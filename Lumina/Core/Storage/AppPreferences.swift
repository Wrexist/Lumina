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
        static let transitAlertsLastPlannedAt = "luminaTransitAlertsLastPlannedAt"
        static let reflectReminderEnabled = "luminaReflectReminderEnabled"
        static let reflectReminderHour = "luminaReflectReminderHour"
        static let reflectReminderMinute = "luminaReflectReminderMinute"
        static let houseSystem = "luminaHouseSystem"
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

    /// The house system the Chart tab renders. Persisted because it was
    /// previously plain view-model state held in a `@State` — so the user's
    /// choice of Whole-sign or Sidereal silently reverted to Placidus on every
    /// relaunch, and Settings claimed "Placidus" regardless.
    var houseSystem: HouseSystem {
        didSet {
            guard oldValue != houseSystem else { return }
            defaults.set(houseSystem.rawValue, forKey: Keys.houseSystem)
        }
    }

    /// Opt-in: schedule on-device notifications for upcoming exact transits.
    var transitAlertsEnabled: Bool {
        didSet {
            guard oldValue != transitAlertsEnabled else { return }
            defaults.set(transitAlertsEnabled, forKey: Keys.transitAlertsEnabled)
        }
    }

    /// When transit alerts were last successfully planned.
    /// `TransitAlertsRefresher` uses this to skip app-activation re-plans
    /// younger than 24 h (birth-data changes always re-plan regardless).
    var transitAlertsLastPlannedAt: Date? {
        didSet {
            guard oldValue != transitAlertsLastPlannedAt else { return }
            if let transitAlertsLastPlannedAt {
                defaults.set(transitAlertsLastPlannedAt, forKey: Keys.transitAlertsLastPlannedAt)
            } else {
                defaults.removeObject(forKey: Keys.transitAlertsLastPlannedAt)
            }
        }
    }

    /// Opt-in: one gentle evening reminder that the day's reflection prompt
    /// is ready. Deliberately streak-free — see `ReflectReminderScheduler`.
    var reflectReminderEnabled: Bool {
        didSet {
            guard oldValue != reflectReminderEnabled else { return }
            defaults.set(reflectReminderEnabled, forKey: Keys.reflectReminderEnabled)
        }
    }

    /// Local hour (0–23) the daily reflection reminder fires. Default 21 (9 PM).
    var reflectReminderHour: Int {
        didSet {
            guard oldValue != reflectReminderHour else { return }
            defaults.set(reflectReminderHour, forKey: Keys.reflectReminderHour)
        }
    }

    /// Local minute (0–59) the daily reflection reminder fires. Default 0.
    var reflectReminderMinute: Int {
        didSet {
            guard oldValue != reflectReminderMinute else { return }
            defaults.set(reflectReminderMinute, forKey: Keys.reflectReminderMinute)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.lockReflectWithFaceID = defaults.bool(forKey: Keys.lockReflectWithFaceID)
        self.reduceMotionOverride = defaults.bool(forKey: Keys.reduceMotionOverride)
        self.transitAlertsEnabled = defaults.bool(forKey: Keys.transitAlertsEnabled)
        self.transitAlertsLastPlannedAt = defaults.object(forKey: Keys.transitAlertsLastPlannedAt) as? Date
        self.reflectReminderEnabled = defaults.bool(forKey: Keys.reflectReminderEnabled)
        self.reflectReminderHour = defaults.object(forKey: Keys.reflectReminderHour) as? Int ?? 21
        self.reflectReminderMinute = defaults.object(forKey: Keys.reflectReminderMinute) as? Int ?? 0
        self.houseSystem = (defaults.string(forKey: Keys.houseSystem)
            .flatMap(HouseSystem.init(rawValue:))) ?? .placidus
    }
}
