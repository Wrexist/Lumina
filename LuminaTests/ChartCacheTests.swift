@testable import Lumina
import XCTest

/// `ChartCache` is the one front door to the ephemeris layer. These pin the two
/// behaviours the app leans on: the natal chart is fetched once then served from
/// memory and disk (offline-instant cold launch), day-scoped reads are memoized
/// for the calendar day, and `clear()` erases the persisted chart (Apple 5.1.1(v)).
///
/// `@MainActor` because the fixtures call `BirthChartViewModel.sampleChart()`,
/// which is main-actor isolated.
@MainActor
final class ChartCacheTests: XCTestCase {
    private func makeDefaults() throws -> UserDefaults {
        let suite = "lumina.tests.chartcache.\(UUID().uuidString)"
        return try XCTUnwrap(UserDefaults(suiteName: suite))
    }

    private func makeBirth() -> BirthData {
        BirthData(
            birthDate: Date(timeIntervalSince1970: 645_000_000),
            birthTime: Date(timeIntervalSince1970: 645_050_000),
            placeName: "Stockholm",
            latitude: 59.33,
            longitude: 18.07,
            timeZoneIdentifier: "Europe/Stockholm"
        )
    }

    private func makeTransits() -> TransitsResult {
        TransitsResult(
            calculatedAt: Date(timeIntervalSince1970: 0),
            transitAt: Date(timeIntervalSince1970: 0),
            transitingPlanets: [],
            transits: []
        )
    }

    func testChartFetchedOnceThenServedFromMemory() async throws {
        let store = NatalChartDiskStore(defaults: try makeDefaults())
        let fake = FakeEphemeris(chart: BirthChartViewModel.sampleChart(), transits: makeTransits())
        let cache = ChartCache(service: fake, store: store)
        let birth = makeBirth()

        let first = try await cache.chart(for: birth)
        let second = try await cache.chart(for: birth)

        XCTAssertEqual(first, second)
        let calls = await fake.chartCalls
        XCTAssertEqual(calls, 1, "the second read must come from the in-memory cache")
    }

    func testChartPersistsSoAFreshCacheServesItOffline() async throws {
        let defaults = try makeDefaults()
        let birth = makeBirth()
        let sample = BirthChartViewModel.sampleChart()

        let warm = ChartCache(
            service: FakeEphemeris(chart: sample, transits: makeTransits()),
            store: NatalChartDiskStore(defaults: defaults)
        )
        _ = try await warm.chart(for: birth)

        // A brand-new cache over the same store — its service would throw if
        // ever hit, proving the chart came from disk, not the network.
        let coldService = FakeEphemeris(chart: sample, transits: makeTransits())
        let cold = ChartCache(service: coldService, store: NatalChartDiskStore(defaults: defaults))
        let served = try await cold.chart(for: birth)

        XCTAssertEqual(served, sample)
        let calls = await coldService.chartCalls
        XCTAssertEqual(calls, 0, "a persisted chart must not touch the service")
    }

    func testDayScopedTransitsAreMemoized() async throws {
        let store = NatalChartDiskStore(defaults: try makeDefaults())
        let fake = FakeEphemeris(chart: BirthChartViewModel.sampleChart(), transits: makeTransits())
        let cache = ChartCache(service: fake, store: store)
        let birth = makeBirth()

        _ = try await cache.transits(for: birth)
        _ = try await cache.transits(for: birth)

        let calls = await fake.transitCalls
        XCTAssertEqual(calls, 1, "same-day transits must be served from the cache")
    }

    func testClearErasesThePersistedChart() async throws {
        let defaults = try makeDefaults()
        let store = NatalChartDiskStore(defaults: defaults)
        let cache = ChartCache(
            service: FakeEphemeris(chart: BirthChartViewModel.sampleChart(), transits: makeTransits()),
            store: store
        )
        _ = try await cache.chart(for: makeBirth())
        XCTAssertFalse(store.read().isEmpty)

        await cache.clear()
        XCTAssertTrue(store.read().isEmpty)
    }

    /// Today and Chart both ask for the natal chart on cold launch. Before the
    /// in-flight map they each issued a `/chart` request — two round trips for
    /// one answer, and a lost disk write because both read the store before
    /// either wrote.
    func testConcurrentColdLaunchReadsShareOneFetch() async throws {
        let store = NatalChartDiskStore(defaults: try makeDefaults())
        let fake = FakeEphemeris(chart: BirthChartViewModel.sampleChart(), transits: makeTransits())
        await fake.setChartDelay(nanoseconds: 50_000_000)
        let cache = ChartCache(service: fake, store: store)
        let birth = makeBirth()

        async let first = cache.chart(for: birth)
        async let second = cache.chart(for: birth)
        let (a, b) = try await (first, second)

        XCTAssertEqual(a, b)
        let calls = await fake.chartCalls
        XCTAssertEqual(calls, 1, "simultaneous callers must share one network fetch")
    }

    /// A failed fetch must leave nothing behind — including no in-flight entry
    /// that a later caller would await forever.
    func testFailedFetchIsNotCachedAndDoesNotWedgeLaterReads() async throws {
        let store = NatalChartDiskStore(defaults: try makeDefaults())
        let fake = FakeEphemeris(chart: BirthChartViewModel.sampleChart(), transits: makeTransits())
        await fake.failNextChart()
        let cache = ChartCache(service: fake, store: store)
        let birth = makeBirth()

        do {
            _ = try await cache.chart(for: birth)
            XCTFail("expected the first fetch to fail")
        } catch {
            // Expected.
        }

        let recovered = try await cache.chart(for: birth)
        XCTAssertEqual(recovered, BirthChartViewModel.sampleChart())
        let calls = await fake.chartCalls
        XCTAssertEqual(calls, 2, "the retry must reach the service, not a cached failure")
    }

    func testDiskStoreRoundTripsAndClears() throws {
        let store = NatalChartDiskStore(defaults: try makeDefaults())
        let entry = PersistedNatalChart(
            birthData: makeBirth(),
            houseSystem: .placidus,
            chart: BirthChartViewModel.sampleChart()
        )
        store.write(["key": entry])

        let read = store.read()
        XCTAssertEqual(read["key"]?.chart, entry.chart)
        XCTAssertTrue(read["key"]?.matches(makeBirth(), .placidus) ?? false)

        store.clear()
        XCTAssertTrue(store.read().isEmpty)
    }
}

/// A stand-in provider that counts calls and returns canned results, so the
/// cache's memoization and persistence can be pinned without the network.
private actor FakeEphemeris: EphemerisProviding {
    private(set) var chartCalls = 0
    private(set) var transitCalls = 0
    private let cannedChart: NatalChart
    private let cannedTransits: TransitsResult
    private var chartDelayNanoseconds: UInt64 = 0
    private var shouldFailNextChart = false

    init(chart: NatalChart, transits: TransitsResult) {
        self.cannedChart = chart
        self.cannedTransits = transits
    }

    /// Widens the window in which a second caller can arrive mid-fetch.
    func setChartDelay(nanoseconds: UInt64) {
        chartDelayNanoseconds = nanoseconds
    }

    func failNextChart() {
        shouldFailNextChart = true
    }

    func chart(for birthData: BirthData, houseSystem: HouseSystem?) async throws -> NatalChart {
        chartCalls += 1
        if chartDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: chartDelayNanoseconds)
        }
        if shouldFailNextChart {
            shouldFailNextChart = false
            throw TestError.unimplemented
        }
        return cannedChart
    }

    func transits(for birthData: BirthData, at moment: Date?) async throws -> TransitsResult {
        transitCalls += 1
        return cannedTransits
    }

    func moonPhase(at moment: Date?) async throws -> MoonPhaseResult { throw TestError.unimplemented }
    func retrogrades(at moment: Date?) async throws -> RetrogradesResult { throw TestError.unimplemented }
    func progressions(for birthData: BirthData, on date: Date?) async throws -> ProgressionsResult {
        throw TestError.unimplemented
    }

    func returns(for birthData: BirthData, from: Date?) async throws -> ReturnsResult { throw TestError.unimplemented }
    func forecast(for birthData: BirthData, from: Date?, days: Int?) async throws -> ForecastResult {
        throw TestError.unimplemented
    }

    func synastry(personA: SynastryPerson, personB: SynastryPerson) async throws -> SynastryResult {
        throw TestError.unimplemented
    }

    func composite(personA: SynastryPerson, personB: SynastryPerson) async throws -> CompositeResult {
        throw TestError.unimplemented
    }

    private enum TestError: Error { case unimplemented }
}
