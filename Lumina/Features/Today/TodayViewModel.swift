import Foundation
import OSLog

/// View model for the Today (Home) tab. Loads the user's natal chart so the
/// Big 3 band renders against real placements, the live sky (transits to
/// that chart) so the reading describes what is *actually* aspecting the
/// user right now, and the shared sky context (Moon, retrogrades,
/// progressions, returns) in one coordinated fan-out on a single
/// `EphemerisService` — never invented copy.
///
/// Real RAG-backed reading body + ElevenLabs audio land with Phase 3/5 of
/// `ROADMAP.md`. The transit lines here are the deterministic, honest
/// stand-in until then.
@MainActor
@Observable
final class TodayViewModel {
    enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case ready
        case missingBirthData
        case failed(LuminaError)
    }

    private let logger = Logger(subsystem: "app.lumina.ios", category: "TodayViewModel")
    private let store: UserBirthDataStore
    private let ephemeris: EphemerisService

    private(set) var state: LoadState = .idle
    private(set) var natalChart: NatalChart?
    /// Transit→natal aspects for right now, tightest-orb-first (backend order).
    private(set) var transits: [TransitReading] = []
    /// `true` when the transit fetch itself failed — the reading card then
    /// shows a retry state instead of pretending the sky is quiet.
    private(set) var transitsUnavailable = false
    /// `true` while `retryTransits()` is in flight.
    private(set) var transitsRetrying = false

    // Sky context — fetched in the same fan-out and assigned in one pass so
    // the cards reveal together instead of popping in one by one. `nil`
    // after loading means that fetch failed and its card simply doesn't
    // render (no invented content).
    private(set) var skyContextLoading = false
    private(set) var moonPhase: MoonPhaseResult?
    private(set) var retrogrades: RetrogradesResult?
    private(set) var progressions: ProgressionsResult?
    /// Jupiter/Saturn returns landing within the next year, soonest first.
    private(set) var imminentReturns: [ReturnEvent] = []

    /// What the current content was loaded against — `loadIfNeeded()` reloads
    /// when either moves (birth info edited in Settings, or the calendar day
    /// rolled over in a long-lived process).
    private var loadedRevision: Int?
    private var loadedDay: Date?

    init(
        store: UserBirthDataStore = .userDefaults,
        ephemeris: EphemerisService = EphemerisService()
    ) {
        self.store = store
        self.ephemeris = ephemeris
    }

    /// Splits the sorted transits into the headline line and the secondary
    /// "details" lines. Pure — testable without the network.
    static func todayLines(
        from transits: [TransitReading],
        maxSecondary: Int = 3
    ) -> (headline: String?, secondary: [String]) {
        let phrased = transits.map(TransitPhrasing.sentence)
        return (phrased.first, Array(phrased.dropFirst().prefix(maxSecondary)))
    }

    /// The current headline + secondary lines from the loaded transits.
    var todayLines: (headline: String?, secondary: [String]) {
        Self.todayLines(from: transits)
    }

    /// The progressed chapter is only *news* around a progressed-Moon sign
    /// change; mid-season it demotes below the quick actions.
    var chapterIsTimely: Bool {
        progressions.map { ProgressedChapter.isNearCusp($0) } ?? false
    }

    func loadIfNeeded() async {
        switch state {
        case .loading:
            return
        case .ready where contentIsFresh:
            return
        default:
            break
        }
        guard let birthData = store.load() else {
            state = .missingBirthData
            return
        }
        state = .loading
        loadedRevision = store.revision
        loadedDay = .now
        skyContextLoading = true

        // One fan-out on the one shared service: the sky-context quartet
        // runs concurrently with the critical path (chart + transits).
        async let skyLoad: Void = loadSkyContext(for: birthData)
        await loadChartAndTransits(for: birthData)
        await skyLoad
        applyDebugSkyFallbacks()
        skyContextLoading = false
    }

    /// Content loaded earlier is still current unless the birth data was
    /// edited in Settings or the calendar day rolled over since we loaded.
    private var contentIsFresh: Bool {
        guard loadedRevision == store.revision, let loadedDay else { return false }
        return Calendar.current.isDate(loadedDay, inSameDayAs: .now)
    }

    /// The critical path. The natal chart hard-fails the screen; the transit
    /// list gets its own inline retry state instead — never the "quiet sky"
    /// copy, which would be invented content on a fetch failure.
    private func loadChartAndTransits(for birthData: BirthData) async {
        async let chartLoad = ephemeris.chart(for: birthData)
        async let transitsLoad = ephemeris.transits(for: birthData)
        do {
            natalChart = try await chartLoad
            if let result = try? await transitsLoad {
                transits = result.transits
                transitsUnavailable = false
            } else {
                transits = []
                transitsUnavailable = true
            }
            state = .ready
        } catch {
            logger.error("today load failed: \(error.localizedDescription)")
            transits = []
            #if DEBUG
            // Dev builds often run without a Swiss Eph URL; fall back to the
            // sample chart + sample transits so the shell stays exercisable.
            natalChart = BirthChartViewModel.sampleChart()
            transits = Self.sampleTransits()
            transitsUnavailable = false
            state = .ready
            #else
            // In production a real failure must surface, not silently show
            // someone else's chart.
            state = .failed(LuminaError.from(error))
            #endif
        }
    }

    /// The best-effort quartet, assigned in one pass so the cards reveal
    /// together. A failed fetch leaves `nil` and its card doesn't render.
    private func loadSkyContext(for birthData: BirthData) async {
        async let moonLoad = ephemeris.moonPhase()
        async let retrogradesLoad = ephemeris.retrogrades()
        async let progressionsLoad = ephemeris.progressions(for: birthData)
        async let returnsLoad = ephemeris.returns(for: birthData)
        moonPhase = try? await moonLoad
        retrogrades = try? await retrogradesLoad
        progressions = try? await progressionsLoad
        let returnsResult = try? await returnsLoad
        imminentReturns = returnsResult.map {
            ReturnPhrasing.imminent($0.events, within: 365, from: .now)
        } ?? []
    }

    /// Same no-backend fallback as the chart path, so dev builds and
    /// previews still exercise the sky-context cards. Runs after both the
    /// critical path and the quartet, when `state` is final.
    private func applyDebugSkyFallbacks() {
        #if DEBUG
        guard state == .ready else { return }
        if moonPhase == nil { moonPhase = Self.sampleMoon }
        if retrogrades == nil { retrogrades = Self.sampleRetrogrades }
        if progressions == nil { progressions = Self.sampleProgressions }
        if imminentReturns.isEmpty { imminentReturns = Self.sampleReturns }
        #endif
    }

    func retry() async {
        state = .idle
        transits = []
        transitsUnavailable = false
        await loadIfNeeded()
    }

    /// Re-fetches just the transit list after a transit failure — the chart
    /// and sky context are still valid, so no full-screen reload.
    func retryTransits() async {
        guard !transitsRetrying, let birthData = store.load() else { return }
        transitsRetrying = true
        defer { transitsRetrying = false }
        do {
            transits = try await ephemeris.transits(for: birthData).transits
            transitsUnavailable = false
        } catch {
            logger.error("transit retry failed: \(error.localizedDescription)")
            transitsUnavailable = true
        }
    }

    #if DEBUG
    /// Dev-only stand-in transits so previews and no-backend builds can
    /// exercise the Today UI. Never compiled into a release build.
    static func sampleTransits() -> [TransitReading] {
        [
            TransitReading(transiting: "Pluto", natal: "Mercury", type: .trine, exactAngle: 120, orb: 0.4, applying: false),
            TransitReading(transiting: "Venus", natal: "Venus", type: .sextile, exactAngle: 60, orb: 0.5, applying: true),
            TransitReading(transiting: "Saturn", natal: "Neptune", type: .square, exactAngle: 90, orb: 1.3, applying: true),
            TransitReading(transiting: "Moon", natal: "Jupiter", type: .opposition, exactAngle: 180, orb: 1.3, applying: false),
        ]
    }

    /// Dev-only stand-ins for the sky-context quartet (moved here from the
    /// cards, which are now dumb renderers of passed-in data).
    private static let sampleMoon = MoonPhaseResult(
        calculatedAt: .now,
        at: .now,
        angle: 236,
        phase: "Waning Gibbous",
        illumination: 0.78,
        nextNewMoon: .now.addingTimeInterval(86_400 * 12),
        nextFullMoon: .now.addingTimeInterval(86_400 * 24)
    )

    private static let sampleRetrogrades = RetrogradesResult(
        calculatedAt: .now,
        at: .now,
        planets: [
            RetrogradeState(
                planet: "Mercury",
                isRetrograde: true,
                nextStationAt: .now.addingTimeInterval(86_400 * 9),
                nextStationDirection: .direct
            ),
            RetrogradeState(planet: "Venus", isRetrograde: false, nextStationAt: nil, nextStationDirection: nil),
        ]
    )

    private static let sampleProgressions = ProgressionsResult(
        calculatedAt: .now,
        on: .now,
        progressedAt: .now,
        planets: [
            NatalChart.PlanetPosition(planet: "Sun", longitude: 130, latitude: 0, isRetrograde: false),
            NatalChart.PlanetPosition(planet: "Moon", longitude: 215, latitude: 0, isRetrograde: false),
        ]
    )

    private static let sampleReturns = [
        ReturnEvent(
            planet: "Saturn",
            returnNumber: 1,
            exactAt: .now.addingTimeInterval(86_400 * 120),
            natalLongitude: 280
        ),
    ]
    #endif
}
