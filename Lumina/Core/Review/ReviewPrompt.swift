import Foundation

/// Decides whether the app has earned the right to ask for an App Store
/// rating, and remembers that it asked.
///
/// The rule is engagement first: we only ask after the daily reading has been
/// unveiled on `requiredEngagedDays` *distinct* calendar days. Someone who
/// opened the app once and left is never asked, so the ratings that do arrive
/// come from people who actually use it — which is also the only kind of
/// rating worth having on the product page.
///
/// Two things this deliberately never does:
///
/// - **Ask on an error.** `TodayHubView` calls `recordEngagement()` from the
///   happy-path unveil only, and that path is unreachable when the transit
///   fetch failed (see `loadedContent`). A failed reading is not the moment to
///   ask how we're doing.
/// - **Ask twice on one version.** One ask per marketing version, whether or
///   not the system actually drew anything.
///
/// Apple's own throttle — at most three prompts per user per year, and none at
/// all if the user turned them off in Settings — sits underneath this. Ours is
/// the stricter of the two, on purpose.
///
/// `UserDefaults`, `Calendar` and the version string are injectable so tests
/// can isolate persistence and pin both the day boundary and the "new release"
/// case (see `ReviewPromptTests`).
@MainActor
final class ReviewPrompt {
    private enum Keys {
        static let engagedDays = "luminaReviewEngagedDays"
        static let askedVersion = "luminaReviewAskedVersion"
    }

    /// Distinct days of real use before the first ask. Three is a deliberate
    /// choice: one day is a stranger, two could be curiosity, three is a
    /// habit forming.
    nonisolated static let requiredEngagedDays = 3

    /// Only the most recent days are kept. The decision needs a count above a
    /// small threshold, not a history, and an unbounded array in
    /// `UserDefaults` is a slow leak nobody would ever notice.
    nonisolated static let storedDayLimit = 8

    static let shared = ReviewPrompt()

    /// Marketing version ("1.0"). Keyed on this rather than the build number
    /// so a TestFlight build train doesn't burn the ask, and so the *next*
    /// release may ask once more — six months of new work is a fair reason to
    /// ask someone who ignored the prompt the first time.
    nonisolated static var marketingVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    private let defaults: UserDefaults
    private let calendar: Calendar
    private let version: String

    /// Distinct "yyyy-MM-dd" days the reading was unveiled on, most recent
    /// last, capped at `storedDayLimit`.
    private(set) var engagedDays: [String]

    /// The marketing version we last asked on (`nil` if we never have).
    private(set) var askedVersion: String?

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current, version: String = ReviewPrompt.marketingVersion) {
        self.defaults = defaults
        self.calendar = calendar
        self.version = version
        engagedDays = defaults.stringArray(forKey: Keys.engagedDays) ?? []
        askedVersion = defaults.string(forKey: Keys.askedVersion)
    }

    /// Whether the app has earned an ask right now.
    var isEligible: Bool {
        Self.isEligible(engagedDayCount: engagedDays.count, askedVersion: askedVersion, currentVersion: version)
    }

    /// The whole decision as a pure function — the part worth testing, and the
    /// part that must stay readable when someone later wants to loosen it.
    nonisolated static func isEligible(engagedDayCount: Int, askedVersion: String?, currentVersion: String) -> Bool {
        guard engagedDayCount >= requiredEngagedDays else { return false }
        return askedVersion != currentVersion
    }

    /// Records that the user unveiled the reading on the day containing
    /// `date`. Idempotent within a calendar day: opening the app five times in
    /// one evening is one day of engagement, not five.
    func recordEngagement(on date: Date = .now) {
        let day = DailyRevealState.dayKey(for: date, calendar: calendar)
        guard !engagedDays.contains(day) else { return }
        engagedDays = Array((engagedDays + [day]).suffix(Self.storedDayLimit))
        defaults.set(engagedDays, forKey: Keys.engagedDays)
    }

    /// Records that the ask happened on this version. Called whether or not
    /// the system actually drew a prompt — `requestReview` reports nothing
    /// back, so a silently throttled ask still has to burn the slot. The
    /// alternative is re-triggering on every single unveil forever.
    func markAsked() {
        askedVersion = version
        defaults.set(version, forKey: Keys.askedVersion)
    }

    /// Erases the record — used by account deletion, so a fresh account on the
    /// same device isn't asked on its first day because of the last one.
    func clear() {
        engagedDays = []
        askedVersion = nil
        defaults.removeObject(forKey: Keys.engagedDays)
        defaults.removeObject(forKey: Keys.askedVersion)
    }
}
