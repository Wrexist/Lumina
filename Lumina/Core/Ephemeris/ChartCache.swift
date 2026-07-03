import Foundation

/// The one shared, day-aware front door to `EphemerisService`.
///
/// Every view and view-model routes ephemeris reads through `ChartCache.shared`
/// instead of newing up its own stateless service. Two wins fall out of that:
///
/// 1. **Instant cold launch.** The natal chart never changes day-to-day, so the
///    first successful fetch is persisted to disk. Subsequent launches return it
///    synchronously (no network) — Chart, the Big-3 band, and the widget paint
///    offline in <50ms.
/// 2. **No duplicate work.** Today, Reflect, Forecast, and the notification
///    refreshers all ask for the same day's transits / moon / forecast. The
///    day-scoped in-memory cache serves the second caller from memory; a rolled
///    calendar day flushes it so the sky is never stale.
///
/// Only the "today / now" variants are cached — an explicit-date read still
/// belongs on `EphemerisService` directly. Errors are never cached, so a failed
/// fetch is always retried (and the DEBUG sample-chart fallbacks in the view
/// models still fire, because `.missingConfiguration` propagates unchanged).
protocol EphemerisProviding: Sendable {
    func chart(for birthData: BirthData, houseSystem: HouseSystem?) async throws -> NatalChart
    func transits(for birthData: BirthData, at moment: Date?) async throws -> TransitsResult
    func moonPhase(at moment: Date?) async throws -> MoonPhaseResult
    func retrogrades(at moment: Date?) async throws -> RetrogradesResult
    func progressions(for birthData: BirthData, on date: Date?) async throws -> ProgressionsResult
    func returns(for birthData: BirthData, from: Date?) async throws -> ReturnsResult
    func forecast(for birthData: BirthData, from: Date?, days: Int?) async throws -> ForecastResult
    func synastry(personA: SynastryPerson, personB: SynastryPerson) async throws -> SynastryResult
    func composite(personA: SynastryPerson, personB: SynastryPerson) async throws -> CompositeResult
}

// EphemerisService already declares every one of these (with default args), so
// the conformance is satisfied as-is.
extension EphemerisService: EphemerisProviding {}

actor ChartCache {
    static let shared = ChartCache()

    private let service: any EphemerisProviding
    private let store: any NatalChartStore

    // Day-invariant, persisted across launches, keyed by (birthData, houseSystem).
    private var natalCache: [String: NatalChart] = [:]

    // Day-scoped: flushed whenever the calendar day rolls over.
    private var cachedDay: String?
    private var transitsCache: [String: TransitsResult] = [:]
    private var moonCache: MoonPhaseResult?
    private var retrogradesCache: RetrogradesResult?
    private var progressionsCache: [String: ProgressionsResult] = [:]
    private var returnsCache: [String: ReturnsResult] = [:]
    private var forecastCache: [String: ForecastResult] = [:]
    private var synastryCache: [String: SynastryResult] = [:]
    private var compositeCache: [String: CompositeResult] = [:]

    init(
        service: any EphemerisProviding = EphemerisService(),
        store: any NatalChartStore = NatalChartDiskStore()
    ) {
        self.service = service
        self.store = store
    }

    /// The natal chart. Served from memory, then disk, then the network —
    /// persisting on the first successful fetch so later launches are offline-instant.
    func chart(for birthData: BirthData, houseSystem: HouseSystem? = nil) async throws -> NatalChart {
        let key = natalKey(birthData, houseSystem)
        if let hit = natalCache[key] { return hit }
        var persisted = store.read()
        if let entry = persisted[key], entry.matches(birthData, houseSystem) {
            natalCache[key] = entry.chart
            return entry.chart
        }
        let chart = try await service.chart(for: birthData, houseSystem: houseSystem)
        natalCache[key] = chart
        // Keep only the current birth data's charts, then persist this one.
        persisted = persisted.filter { $0.value.birthData == birthData }
        persisted[key] = PersistedNatalChart(birthData: birthData, houseSystem: houseSystem, chart: chart)
        store.write(persisted)
        return chart
    }

    /// Today's transit→natal aspects.
    func transits(for birthData: BirthData) async throws -> TransitsResult {
        flushDayScopedIfNeeded()
        let key = encodeKey(birthData)
        if let hit = transitsCache[key] { return hit }
        let result = try await service.transits(for: birthData, at: nil)
        transitsCache[key] = result
        return result
    }

    /// Tonight's Moon (global — no birth input).
    func moonPhase() async throws -> MoonPhaseResult {
        flushDayScopedIfNeeded()
        if let hit = moonCache { return hit }
        let result = try await service.moonPhase(at: nil)
        moonCache = result
        return result
    }

    /// Which bodies are retrograde now (global — no birth input).
    func retrogrades() async throws -> RetrogradesResult {
        flushDayScopedIfNeeded()
        if let hit = retrogradesCache { return hit }
        let result = try await service.retrogrades(at: nil)
        retrogradesCache = result
        return result
    }

    /// Today's secondary-progressed chart.
    func progressions(for birthData: BirthData) async throws -> ProgressionsResult {
        flushDayScopedIfNeeded()
        let key = encodeKey(birthData)
        if let hit = progressionsCache[key] { return hit }
        let result = try await service.progressions(for: birthData, on: nil)
        progressionsCache[key] = result
        return result
    }

    /// Upcoming Jupiter/Saturn returns from now.
    func returns(for birthData: BirthData) async throws -> ReturnsResult {
        flushDayScopedIfNeeded()
        let key = encodeKey(birthData)
        if let hit = returnsCache[key] { return hit }
        let result = try await service.returns(for: birthData, from: nil)
        returnsCache[key] = result
        return result
    }

    /// The default upcoming-transit forecast window from now.
    func forecast(for birthData: BirthData) async throws -> ForecastResult {
        flushDayScopedIfNeeded()
        let key = encodeKey(birthData)
        if let hit = forecastCache[key] { return hit }
        let result = try await service.forecast(for: birthData, from: nil, days: nil)
        forecastCache[key] = result
        return result
    }

    /// Synastry cross-aspects between two people.
    func synastry(personA: SynastryPerson, personB: SynastryPerson) async throws -> SynastryResult {
        flushDayScopedIfNeeded()
        let key = encodeKey([personA, personB])
        if let hit = synastryCache[key] { return hit }
        let result = try await service.synastry(personA: personA, personB: personB)
        synastryCache[key] = result
        return result
    }

    /// The composite (midpoint) chart of two people.
    func composite(personA: SynastryPerson, personB: SynastryPerson) async throws -> CompositeResult {
        flushDayScopedIfNeeded()
        let key = encodeKey([personA, personB])
        if let hit = compositeCache[key] { return hit }
        let result = try await service.composite(personA: personA, personB: personB)
        compositeCache[key] = result
        return result
    }

    /// Drops every cached value and the persisted chart. Called by the
    /// account eraser (Apple 5.1.1(v)) so nothing of a deleted account survives.
    func clear() {
        natalCache.removeAll()
        cachedDay = nil
        transitsCache.removeAll()
        moonCache = nil
        retrogradesCache = nil
        progressionsCache.removeAll()
        returnsCache.removeAll()
        forecastCache.removeAll()
        synastryCache.removeAll()
        compositeCache.removeAll()
        store.clear()
    }

    // MARK: - Keys

    private func natalKey(_ birthData: BirthData, _ houseSystem: HouseSystem?) -> String {
        encodeKey(birthData) + "|" + (houseSystem?.rawValue ?? "default")
    }

    /// A stable, launch-invariant key. `Hashable.hashValue` is per-process
    /// randomized, so we key on the canonical JSON instead.
    private func encodeKey(_ value: some Encodable) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(value), let string = String(data: data, encoding: .utf8) else {
            return ""
        }
        return string
    }

    /// Clears the day-scoped caches when the calendar day has rolled over.
    private func flushDayScopedIfNeeded() {
        let today = Self.dayString()
        guard today != cachedDay else { return }
        cachedDay = today
        transitsCache.removeAll()
        moonCache = nil
        retrogradesCache = nil
        progressionsCache.removeAll()
        returnsCache.removeAll()
        forecastCache.removeAll()
        synastryCache.removeAll()
        compositeCache.removeAll()
    }

    private static func dayString(_ date: Date = .now) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
}
