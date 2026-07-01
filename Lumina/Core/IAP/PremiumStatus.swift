import Foundation

/// Main-actor, synchronously-readable mirror of the current `lumina_plus`
/// entitlement. `IAPManager` is an `actor`, so views can't read its state
/// directly from `body` — this small observable singleton is the seam,
/// mirroring `Core/Notifications/NotificationPermission.swift`'s shape.
///
/// `IAPManager` is the only writer: on `configure`'s initial `customerInfo`
/// fetch, on the `PurchasesDelegate` callback, and after purchase/restore
/// calls complete.
@MainActor
@Observable
final class PremiumStatus {
    static let shared = PremiumStatus()

    private(set) var isPremium = false

    private init() {}

    /// `IAPManager`-only write path — keeps `isPremium` externally read-only
    /// (matching `NotificationPermission`'s `private(set)` shape) while still
    /// letting the actor push updates from configure/delegate/purchase call
    /// sites.
    func update(isPremium: Bool) {
        self.isPremium = isPremium
    }
}
