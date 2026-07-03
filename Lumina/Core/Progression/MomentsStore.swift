import Foundation

/// A milestone the user has actually lived through — a chart met, a page
/// written, a sky witnessed. Moments are deliberately anti-streak: nothing
/// here expires, nothing counts down, and nothing scolds. We only ever
/// celebrate what HAS happened (see `docs/NAVIGATION.md` §13 — the brand
/// stays quiet).
enum Moment: String, CaseIterable, Codable, Sendable {
    case firstChart
    case firstFriend
    case firstReflection
    case tenReflections
    case twentyFiveReflections
    case firstRitual
    case allMoonPhases
    case chartExplorer

    var title: String {
        switch self {
        case .firstChart: return "You met your chart"
        case .firstFriend: return "Your first companion"
        case .firstReflection: return "Your first reflection"
        case .tenReflections: return "Ten reflections"
        case .twentyFiveReflections: return "Twenty-five reflections"
        case .firstRitual: return "A moon ritual begun"
        case .allMoonPhases: return "Every face of the Moon"
        case .chartExplorer: return "You've met your whole chart"
        }
    }

    /// One warm, honest sentence shown once the moment is unlocked.
    var subtitle: String {
        switch self {
        case .firstChart:
            return "The sky as it stood when you arrived — mapped, and yours to return to."
        case .firstFriend:
            return "Someone else's sky, kept beside your own."
        case .firstReflection:
            return "One page, written under the day's sky. That's how it begins."
        case .tenReflections:
            return "Ten pages of your own sky, written in your words."
        case .twentyFiveReflections:
            return "Twenty-five entries — a record only you could have written."
        case .firstRitual:
            return "You met a moon phase with intention, not just a glance."
        case .allMoonPhases:
            return "You were here for all eight faces of the Moon, new through waning."
        case .chartExplorer:
            return "Every placement in your chart, opened and read."
        }
    }

    /// SF Symbol for the moment's icon — celestial, never trophy-like.
    var systemImage: String {
        switch self {
        case .firstChart: return "sparkles"
        case .firstFriend: return "person.2"
        case .firstReflection: return "book.closed"
        case .tenReflections: return "book"
        case .twentyFiveReflections: return "books.vertical"
        case .firstRitual: return "moon.stars"
        case .allMoonPhases: return "moonphase.full.moon"
        case .chartExplorer: return "circles.hexagonpath"
        }
    }

    /// Shown on locked "Still ahead" rows in `MomentsView`. Honest hints —
    /// what would earn it, never how far behind the user is.
    var lockedHint: String {
        switch self {
        case .firstChart:
            return "Cast your birth chart to see the sky you were born under."
        case .firstFriend:
            return "Add someone to People, and their sky sits beside yours."
        case .firstReflection:
            return "Write one reflection — a sentence is enough."
        case .tenReflections:
            return "Ten reflections, gathered whenever you feel like writing."
        case .twentyFiveReflections:
            return "Twenty-five reflections, in your own time."
        case .firstRitual:
            return "Begin a ritual from the Moon card, any phase you like."
        case .allMoonPhases:
            return "Open Lumina under each of the Moon's eight faces."
        case .chartExplorer:
            return "Open each placement in your chart, one by one."
        }
    }
}

/// Persistent record of unlocked `Moment`s. UserDefaults-backed like
/// `AppPreferences` — singleton for app use, injectable defaults for tests.
///
/// Two separate sets are tracked: *unlocked* (rawValue → unlock date, the
/// permanent record) and *seen* (which unlocks the user has already been
/// shown), so a surface like Today can present a `MomentUnlockCard` exactly
/// once via `latestUnseen` / `markSeen`.
@MainActor
@Observable
final class MomentsStore {
    private enum Keys {
        static let unlocked = "luminaMomentsUnlocked"
        static let seen = "luminaMomentsSeen"
        static let witnessedMoonPhases = "luminaMomentsWitnessedMoonPhases"
    }

    /// The eight phase names the ephemeris backend emits. Anything else
    /// passed to `witnessMoonPhase` is ignored so a renamed or malformed
    /// phase can never make "Every face of the Moon" unreachable or cheap.
    static let moonPhaseNames: Set<String> = [
        "New Moon", "Waxing Crescent", "First Quarter", "Waxing Gibbous",
        "Full Moon", "Waning Gibbous", "Last Quarter", "Waning Crescent"
    ]

    static let shared = MomentsStore()

    private let defaults: UserDefaults
    private var unlockDates: [String: Date]
    private var seenMoments: Set<String>

    /// Distinct backend phase names the user has been present for.
    private(set) var witnessedPhases: Set<String>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.dictionary(forKey: Keys.unlocked) ?? [:]
        self.unlockDates = stored.compactMapValues { $0 as? Date }
        self.seenMoments = Set(defaults.stringArray(forKey: Keys.seen) ?? [])
        // Drop any stored name no longer in the canonical set (symmetric with
        // `ChartDiscovery`), so a renamed phase can't inflate the count and
        // falsely satisfy — or permanently block — "Every face of the Moon".
        let storedPhases = Set(defaults.stringArray(forKey: Keys.witnessedMoonPhases) ?? [])
        self.witnessedPhases = storedPhases.intersection(Self.moonPhaseNames)
    }

    /// Erases all progression state — used by account deletion so a fresh
    /// account on the same device starts with no unlocked moments.
    func clear() {
        unlockDates = [:]
        seenMoments = []
        witnessedPhases = []
        defaults.removeObject(forKey: Keys.unlocked)
        defaults.removeObject(forKey: Keys.seen)
        defaults.removeObject(forKey: Keys.witnessedMoonPhases)
    }

    // MARK: - Unlocking

    /// Unlocks the moment, recording when it happened. Returns `true` only
    /// when this call newly unlocked it — callers use that to decide whether
    /// to play `Haptics.success`. Repeat calls are no-ops.
    @discardableResult
    func unlock(_ moment: Moment, at date: Date = .now) -> Bool {
        guard unlockDates[moment.rawValue] == nil else { return false }
        unlockDates[moment.rawValue] = date
        defaults.set(unlockDates, forKey: Keys.unlocked)
        return true
    }

    func isUnlocked(_ moment: Moment) -> Bool {
        unlockDates[moment.rawValue] != nil
    }

    /// Unlocked moments with their unlock dates, newest first. Ties (same
    /// instant) fall back to rawValue so ordering stays deterministic.
    var unlocked: [(moment: Moment, date: Date)] {
        Moment.allCases
            .compactMap { moment in
                unlockDates[moment.rawValue].map { (moment: moment, date: $0) }
            }
            .sorted { lhs, rhs in
                if lhs.date != rhs.date { return lhs.date > rhs.date }
                return lhs.moment.rawValue < rhs.moment.rawValue
            }
    }

    // MARK: - Seen tracking

    /// The most recently unlocked moment the user hasn't been shown yet, or
    /// `nil` when everything unlocked has been seen. Surfaces show it once,
    /// then call `markSeen(_:)`.
    var latestUnseen: Moment? {
        unlocked.first { !seenMoments.contains($0.moment.rawValue) }?.moment
    }

    func markSeen(_ moment: Moment) {
        guard !seenMoments.contains(moment.rawValue) else { return }
        seenMoments.insert(moment.rawValue)
        defaults.set(seenMoments.sorted(), forKey: Keys.seen)
    }

    // MARK: - Moon phases

    /// Records that the user was present for a moon phase (by backend phase
    /// name). Returns `true` when the witnessed set actually grew. Unknown
    /// names are ignored. Recording the eighth distinct phase auto-unlocks
    /// `.allMoonPhases`.
    @discardableResult
    func witnessMoonPhase(_ phaseName: String) -> Bool {
        guard Self.moonPhaseNames.contains(phaseName),
              !witnessedPhases.contains(phaseName) else { return false }
        witnessedPhases.insert(phaseName)
        defaults.set(witnessedPhases.sorted(), forKey: Keys.witnessedMoonPhases)
        if witnessedPhases.count == Self.moonPhaseNames.count {
            unlock(.allMoonPhases)
        }
        return true
    }

    // MARK: - Reflection milestones

    /// Convenience for the Reflect surfaces: given the total number of
    /// journal entries that now exist, unlocks whichever reflection moments
    /// apply. Counts what the user HAS written — never consecutive days.
    /// Returns `true` when anything was newly unlocked.
    @discardableResult
    func recordReflection(totalCount: Int) -> Bool {
        var newlyUnlocked = false
        if totalCount >= 1 { newlyUnlocked = unlock(.firstReflection) || newlyUnlocked }
        if totalCount >= 10 { newlyUnlocked = unlock(.tenReflections) || newlyUnlocked }
        if totalCount >= 25 { newlyUnlocked = unlock(.twentyFiveReflections) || newlyUnlocked }
        return newlyUnlocked
    }
}
