import Foundation
import OSLog

/// Tiny `@Observable` wrapper around the user-tunable preferences that
/// Settings exposes. UserDefaults-backed; bound to Settings toggles and
/// read by feature views (e.g. ReflectHubView checks
/// `lockReflectWithFaceID`).
///
/// Keep this lean — anything that needs versioning or sync goes through
/// SwiftData, not here.
@MainActor
@Observable
final class AppPreferences {
    private enum Keys {
        static let lockReflectWithFaceID = "luminaLockReflectWithFaceID"
        static let reduceMotionOverride = "luminaReduceMotionOverride"
        static let transitAlertsEnabled = "luminaTransitAlertsEnabled"
    }

    static let shared = AppPreferences()

    private let logger = Logger(subsystem: "app.lumina.ios", category: "AppPreferences")
    private let defaults: UserDefaults

    var lockReflectWithFaceID: Bool {
        didSet {
            guard oldValue != lockReflectWithFaceID else { return }
            defaults.set(lockReflectWithFaceID, forKey: Keys.lockReflectWithFaceID)
        }
    }

    var reduceMotionOverride: Bool {
        didSet {
            guard oldValue != reduceMotionOverride else { return }
            defaults.set(reduceMotionOverride, forKey: Keys.reduceMotionOverride)
        }
    }

    /// Opt-in: schedule on-device notifications for upcoming exact transits.
    var transitAlertsEnabled: Bool {
        didSet {
            guard oldValue != transitAlertsEnabled else { return }
            defaults.set(transitAlertsEnabled, forKey: Keys.transitAlertsEnabled)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.lockReflectWithFaceID = defaults.bool(forKey: Keys.lockReflectWithFaceID)
        self.reduceMotionOverride = defaults.bool(forKey: Keys.reduceMotionOverride)
        self.transitAlertsEnabled = defaults.bool(forKey: Keys.transitAlertsEnabled)
    }
}
