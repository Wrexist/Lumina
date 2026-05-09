import Foundation

/// Tracks paywall presentation state per `ROADMAP.md` §1.7 and Apple
/// Guideline 3.1.2(c) (April 2026 enforcement): we never re-prompt in the
/// same session and the rescue offer fires at most once per install.
@MainActor
@Observable
final class PaywallTracker {
    private enum Keys {
        static let everSeen = "luminaPaywallEverSeen"
        static let rescueShown = "luminaPaywallRescueShown"
        static let lastDeclineDate = "luminaPaywallLastDeclineAt"
    }

    static let shared = PaywallTracker()

    private let defaultsRef: UserDefaults
    private(set) var hasSeenInitialOffer: Bool
    private(set) var hasShownRescue: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaultsRef = defaults
        self.hasSeenInitialOffer = defaults.bool(forKey: Keys.everSeen)
        self.hasShownRescue = defaults.bool(forKey: Keys.rescueShown)
    }

    func recordInitialOfferSeen() {
        hasSeenInitialOffer = true
        defaultsRef.set(true, forKey: Keys.everSeen)
        defaultsRef.set(Date.now, forKey: Keys.lastDeclineDate)
    }

    func recordRescueShown() {
        hasShownRescue = true
        defaultsRef.set(true, forKey: Keys.rescueShown)
    }

    /// `true` exactly once per install — when the user has seen the
    /// initial offer but not yet seen the rescue, AND we're back in
    /// front of them in a different surface (e.g. a Premium-gated tap).
    func shouldShowRescue() -> Bool {
        hasSeenInitialOffer && !hasShownRescue
    }

    /// Test-only helper.
    func reset() {
        hasSeenInitialOffer = false
        hasShownRescue = false
        defaultsRef.removeObject(forKey: Keys.everSeen)
        defaultsRef.removeObject(forKey: Keys.rescueShown)
        defaultsRef.removeObject(forKey: Keys.lastDeclineDate)
    }
}
