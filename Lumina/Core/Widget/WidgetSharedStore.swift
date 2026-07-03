import Foundation

/// The small snapshot the home-screen widget renders. Written by the app on
/// chart load, read by the widget extension via a shared App Group. Pure
/// Foundation so the exact same file compiles into both targets. Degrades
/// gracefully to standard `UserDefaults` when the App Group isn't provisioned
/// (dev/simulator), so nothing crashes — the widget just shows its placeholder.
struct WidgetSnapshot: Codable, Equatable, Sendable {
    let sunSign: String?
    let moonSign: String?
    let risingSign: String?
    /// A short line — the cosmic-signature headline.
    let headline: String

    /// True when at least one of the Big-3 is known, so the widget can decide
    /// between showing the signature and showing its "open the app" invitation.
    var hasSigns: Bool {
        sunSign != nil || moonSign != nil || risingSign != nil
    }
}

enum WidgetSharedStore {
    /// The App Group id (must match both targets' entitlements).
    static let appGroup = "group.app.lumina.ios"
    private static let snapshotKey = "lumina.widget.snapshot"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static func write(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
    }

    static func read() -> WidgetSnapshot? {
        guard let data = defaults.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    /// Wipes the shared snapshot so the home-screen widget stops showing a
    /// chart after account deletion — the App Group container survives an
    /// app-data wipe otherwise.
    static func clear() {
        defaults.removeObject(forKey: snapshotKey)
    }
}
