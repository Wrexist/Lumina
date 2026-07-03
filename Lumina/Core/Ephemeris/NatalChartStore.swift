import Foundation

/// One persisted natal chart plus the inputs it was computed against, so a
/// changed birth date or house system is detected and never served stale.
struct PersistedNatalChart: Codable, Sendable {
    let birthData: BirthData
    let houseSystem: HouseSystem?
    let chart: NatalChart

    func matches(_ birthData: BirthData, _ houseSystem: HouseSystem?) -> Bool {
        self.birthData == birthData && self.houseSystem == houseSystem
    }
}

/// The persistence seam `ChartCache` writes the day-invariant natal chart
/// through. Injectable so tests can pin the round-trip without touching disk.
protocol NatalChartStore: Sendable {
    /// The persisted charts, keyed by `ChartCache`'s natal key. Empty when none.
    func read() -> [String: PersistedNatalChart]
    func write(_ charts: [String: PersistedNatalChart])
    func clear()
}

/// `UserDefaults`-backed store — the same durable, cheap medium the rest of the
/// app's local state uses. The natal chart is a couple of KB of JSON, well
/// within what `UserDefaults` is meant to hold.
struct NatalChartDiskStore: NatalChartStore, @unchecked Sendable {
    private static let key = "luminaCachedNatalChartsV1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func read() -> [String: PersistedNatalChart] {
        guard let data = defaults.data(forKey: Self.key) else { return [:] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([String: PersistedNatalChart].self, from: data)) ?? [:]
    }

    func write(_ charts: [String: PersistedNatalChart]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(charts) else { return }
        defaults.set(data, forKey: Self.key)
    }

    func clear() {
        defaults.removeObject(forKey: Self.key)
    }
}
