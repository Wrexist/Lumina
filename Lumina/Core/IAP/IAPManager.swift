import Foundation
import OSLog
import RevenueCat

/// All RevenueCat access funnels through this actor — `.swiftlint.yml`'s
/// `no_direct_revenuecat_calls_in_views` enforces that views never reference
/// `Purchases.shared` directly.
///
/// Mirrors `EphemerisService`'s "dev-safe no-op" pattern: an empty or
/// unfilled-placeholder API key (the state of `LuminaRevenueCatAPIKeyIOS` in
/// CI and dev builds until the dashboard + real key exist) leaves the actor
/// unconfigured rather than crashing. Every entry point guards on
/// `isConfigured` and throws `.notConfigured` instead of touching
/// `Purchases.shared`.
actor IAPManager {
    enum ManagerError: Error, Equatable {
        case notConfigured
        case noOfferingsAvailable
        /// The requested plan isn't in the current offering. Surfaced rather
        /// than silently substituting another plan — the paywall used to
        /// advertise a monthly option and a discounted annual, then buy the
        /// standard annual regardless.
        case planUnavailable(PremiumPlan)
    }

    /// The plans the paywall can offer. Each maps to a RevenueCat package;
    /// nothing else in the app picks a package.
    enum PremiumPlan: String, Sendable, CaseIterable {
        case monthly
        case annual

        var packageType: PackageType {
            switch self {
            case .monthly: .monthly
            case .annual: .annual
            }
        }
    }

    /// A plan's real, storefront-localized price. The paywall previously
    /// hardcoded "$59.99" / "$9.99 / month", which is wrong for every
    /// non-US storefront and violates Guideline 3.1.2 (the price shown must
    /// be the price charged).
    struct PlanOffer: Sendable, Equatable {
        let plan: PremiumPlan
        /// e.g. "59,99 €" — already formatted for the user's storefront.
        let localizedPrice: String
        /// Introductory offer description if the product carries one,
        /// e.g. "7 days free". `nil` when there is no trial.
        let introductoryOffer: String?
    }

    static let shared = IAPManager()

    private let logger = Logger(subsystem: "app.lumina.ios", category: "IAP")
    private var isConfigured = false
    private var delegateProxy: DelegateProxy?

    private init() {}

    /// Called once from `AppDelegate.application(_:didFinishLaunchingWithOptions:)`
    /// — never from `LuminaApp.init()` (SwiftUI Previews call `init()` in the
    /// simulator and would crash if RevenueCat were configured that early;
    /// see `LEARNINGS.md` "RevenueCat initialization").
    func configure(apiKey: String) {
        guard Self.isRealAPIKey(apiKey) else {
            logger.info("IAP not configured — missing or placeholder API key")
            return
        }

        Purchases.configure(withAPIKey: apiKey)
        let proxy = DelegateProxy(manager: self)
        delegateProxy = proxy
        Purchases.shared.delegate = proxy
        isConfigured = true
        logger.info("IAP configured")

        Task {
            await self.refreshPremiumStatus()
        }
    }

    /// A key is unusable if it's empty or still the unexpanded xcconfig
    /// placeholder (happens when `secrets/Config.xcconfig` isn't generated
    /// yet — see `scripts/inject_env.sh`).
    private static func isRealAPIKey(_ apiKey: String) -> Bool {
        !apiKey.isEmpty && !apiKey.hasPrefix("$(")
    }

    func currentEntitlements() async throws -> Set<Entitlement> {
        guard isConfigured else { throw ManagerError.notConfigured }
        let customerInfo = try await Purchases.shared.customerInfo()
        return Self.entitlements(from: customerInfo)
    }

    /// Real, storefront-localized prices for every plan the current offering
    /// actually sells. The paywall renders these instead of hardcoded USD.
    /// Returns an empty array when unconfigured so the caller can fall back
    /// to non-committal copy rather than quoting a price it can't honour.
    func availableOffers() async -> [PlanOffer] {
        guard isConfigured else { return [] }
        do {
            let offerings = try await Purchases.shared.offerings()
            guard let offering = offerings.current else { return [] }
            return PremiumPlan.allCases.compactMap { plan in
                guard let package = Self.package(for: plan, in: offering) else { return nil }
                let product = package.storeProduct
                return PlanOffer(
                    plan: plan,
                    localizedPrice: product.localizedPriceString,
                    introductoryOffer: product.introductoryDiscount.map {
                        Self.describe(introductory: $0)
                    }
                )
            }
        } catch {
            logger.error("offerings fetch failed: \(error.localizedDescription)")
            return []
        }
    }

    private static func describe(introductory discount: StoreProductDiscount) -> String {
        let unitCount = discount.subscriptionPeriod.value
        let unit: String
        switch discount.subscriptionPeriod.unit {
        case .day: unit = unitCount == 1 ? "day" : "days"
        case .week: unit = unitCount == 1 ? "week" : "weeks"
        case .month: unit = unitCount == 1 ? "month" : "months"
        case .year: unit = unitCount == 1 ? "year" : "years"
        @unknown default: unit = "days"
        }
        return "\(unitCount) \(unit) free"
    }

    /// Purchases a specific plan. Throws `.planUnavailable` rather than
    /// quietly substituting a different package — the paywall showed a
    /// monthly option and a "30% off" annual, then bought the standard
    /// annual either way, so the user was charged a price they were never
    /// shown. User-cancellation is a normal `false` result, not an error.
    func purchase(plan: PremiumPlan) async throws -> Bool {
        guard isConfigured else { throw ManagerError.notConfigured }

        let offerings = try await Purchases.shared.offerings()
        guard let offering = offerings.current else {
            throw ManagerError.noOfferingsAvailable
        }
        guard let package = Self.package(for: plan, in: offering) else {
            throw ManagerError.planUnavailable(plan)
        }

        let result = try await Purchases.shared.purchase(package: package)
        if result.userCancelled {
            logger.info("purchase cancelled by user")
            return false
        }
        await pushPremiumStatus(Self.entitlements(from: result.customerInfo))
        return result.customerInfo.entitlements[Entitlement.luminaPlus.rawValue]?.isActive == true
    }

    private static func package(for plan: PremiumPlan, in offering: Offering) -> Package? {
        switch plan {
        case .monthly: offering.monthly
        case .annual: offering.annual
        }
    }

    /// Wraps `Purchases.shared.restorePurchases()`. Returns whether
    /// `lumina_plus` is active afterward.
    func restorePurchases() async throws -> Bool {
        guard isConfigured else { throw ManagerError.notConfigured }
        let customerInfo = try await Purchases.shared.restorePurchases()
        let entitlements = Self.entitlements(from: customerInfo)
        await pushPremiumStatus(entitlements)
        return entitlements.contains(.luminaPlus)
    }

    /// Re-reads `customerInfo` once (e.g. right after `configure`) and pushes
    /// the result to `PremiumStatus`. Not for repeated view-appear polling —
    /// see `LEARNINGS.md` "Entitlement checking pattern"; the delegate
    /// callback handles ongoing updates.
    private func refreshPremiumStatus() async {
        guard isConfigured else { return }
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await pushPremiumStatus(Self.entitlements(from: customerInfo))
        } catch {
            logger.error("initial customerInfo fetch failed: \(error.localizedDescription)")
        }
    }

    private static func entitlements(from customerInfo: CustomerInfo) -> Set<Entitlement> {
        Set(Entitlement.allCases.filter { customerInfo.entitlements[$0.rawValue]?.isActive == true })
    }

    fileprivate func handleUpdatedCustomerInfo(_ customerInfo: CustomerInfo) async {
        await pushPremiumStatus(Self.entitlements(from: customerInfo))
    }

    private func pushPremiumStatus(_ entitlements: Set<Entitlement>) async {
        let isPremium = entitlements.contains(.luminaPlus)
        await MainActor.run {
            PremiumStatus.shared.update(isPremium: isPremium)
        }
    }

    /// `PurchasesDelegate` conformance lives on a small proxy rather than on
    /// `IAPManager` itself, since the delegate protocol requires synchronous,
    /// non-actor-isolated callbacks — mirroring `AuthManager`'s
    /// `AppleSignInCoordinator` pattern: `nonisolated` delegate methods that
    /// hop back into an isolated context (here, the `IAPManager` actor)
    /// rather than touching actor state directly.
    private final class DelegateProxy: NSObject, PurchasesDelegate, @unchecked Sendable {
        private let manager: IAPManager

        init(manager: IAPManager) {
            self.manager = manager
        }

        nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
            Task {
                await manager.handleUpdatedCustomerInfo(customerInfo)
            }
        }
    }
}
