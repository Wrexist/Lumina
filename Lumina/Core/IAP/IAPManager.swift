import Foundation
import OSLog

/// All RevenueCat access funnels through this actor — `.swiftlint.yml`'s
/// `no_direct_revenuecat_calls_in_views` enforces that views never reference
/// `Purchases.shared` directly.
actor IAPManager {
    enum ManagerError: Error {
        case notConfigured
        case missingAPIKey
    }

    static let shared = IAPManager()

    private let logger = Logger(subsystem: "app.lumina.ios", category: "IAP")
    private var isConfigured = false

    private init() {}

    func configure(apiKey: String) {
        // TODO(lumina): Purchases.configure(withAPIKey: apiKey) — gated until SDK is wired.
        logger.info("IAP configured")
        isConfigured = true
    }

    func currentEntitlements() async throws -> Set<Entitlement> {
        guard isConfigured else { throw ManagerError.notConfigured }
        // TODO(lumina): map Purchases.shared.customerInfo entitlements to `Entitlement`.
        return []
    }
}
