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

    /// Fetches the current offering and attempts to purchase it — the
    /// annual package if one is configured, otherwise the first package
    /// available. Returns whether `lumina_plus` is active afterward.
    /// User-cancellation is a normal `false` result, not a thrown error.
    func purchaseCurrentOffering() async throws -> Bool {
        guard isConfigured else { throw ManagerError.notConfigured }

        let offerings = try await Purchases.shared.offerings()
        guard let offering = offerings.current, let package = Self.preferredPackage(in: offering) else {
            throw ManagerError.noOfferingsAvailable
        }

        let result = try await Purchases.shared.purchase(package: package)
        if result.userCancelled {
            logger.info("purchase cancelled by user")
            return false
        }
        await pushPremiumStatus(Self.entitlements(from: result.customerInfo))
        return result.customerInfo.entitlements[Entitlement.luminaPlus.rawValue]?.isActive == true
    }

    private static func preferredPackage(in offering: Offering) -> Package? {
        offering.annual ?? offering.availablePackages.first
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
