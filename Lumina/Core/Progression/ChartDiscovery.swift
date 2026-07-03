import Foundation

/// Tracks which chart placements the user has actually opened and read —
/// the quiet "chart discovery" collection. Deliberately streak-free: this
/// is a record of real exploration of the user's real chart, not a habit
/// mechanic. The Chart tab renders it as a small map of dots
/// (`ChartDiscoveryBand`).
///
/// UserDefaults-backed with the same injectable idiom as `AppPreferences`;
/// `@Observable` drives UI updates, so no notifications are posted.
@MainActor
@Observable
final class ChartDiscovery {
    private enum Keys {
        static let explored = "luminaChartDiscoveryExplored"
        static let completionCelebrated = "luminaChartDiscoveryCompletionCelebrated"
    }

    /// Canonical placement order: the ten planets, then the Ascendant.
    /// A chart without a birth time has no Ascendant — surfaces filter it
    /// out (via `NatalChart.houses == nil`) rather than special-casing here.
    nonisolated static let placementKeys: [String] = [
        "Sun", "Moon", "Mercury", "Venus", "Mars",
        "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto",
        "Ascendant",
    ]

    static let shared = ChartDiscovery()

    private let defaults: UserDefaults

    /// Placements the user has opened at least once.
    private(set) var explored: Set<String>

    /// Whether the one-time "met your whole chart" celebration has fired.
    /// Persisted so completing the collection celebrates exactly once, ever.
    private(set) var completionCelebrated: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.stringArray(forKey: Keys.explored) ?? []
        self.explored = Set(stored).intersection(Self.placementKeys)
        self.completionCelebrated = defaults.bool(forKey: Keys.completionCelebrated)
    }

    /// Records that the user opened this placement's reading. Returns `true`
    /// only the first time a placement is explored — callers use that to
    /// acknowledge the discovery (one success haptic, nothing louder).
    /// Unknown keys are ignored so the collection stays honest.
    func markExplored(_ key: String) -> Bool {
        guard Self.placementKeys.contains(key), !explored.contains(key) else { return false }
        explored.insert(key)
        defaults.set(explored.sorted(), forKey: Keys.explored)
        return true
    }

    func isExplored(_ key: String) -> Bool {
        explored.contains(key)
    }

    /// Total placements explored so far.
    var exploredCount: Int {
        explored.count
    }

    /// How many of the given keys are explored — callers pass the subset
    /// that exists for the user's chart (no Ascendant without a birth time).
    func exploredCount(of keys: [String]) -> Int {
        keys.filter { explored.contains($0) }.count
    }

    /// Flips the persisted completion flag. Returns `true` exactly once —
    /// the first time it's called — so the full-collection celebration can
    /// never repeat.
    func celebrateCompletionIfNeeded() -> Bool {
        guard !completionCelebrated else { return false }
        completionCelebrated = true
        defaults.set(true, forKey: Keys.completionCelebrated)
        return true
    }

    /// Erases all discovery progress — used by account deletion so a new
    /// account on the same device starts with an empty chart to explore.
    func clear() {
        explored = []
        completionCelebrated = false
        defaults.removeObject(forKey: Keys.explored)
        defaults.removeObject(forKey: Keys.completionCelebrated)
    }
}
