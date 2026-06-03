import Foundation
import OSLog

/// View model for the Today (Home) tab. Loads the user's natal chart so the
/// Big 3 band renders against real placements, and the live sky (transits to
/// that chart) so the headline + "what's happening" lines describe what is
/// *actually* aspecting the user right now — never invented copy.
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

    init(
        store: UserBirthDataStore = .userDefaults,
        ephemeris: EphemerisService = EphemerisService()
    ) {
        self.store = store
        self.ephemeris = ephemeris
    }

    /// Splits the sorted transits into the headline line and the secondary
    /// "what's happening" lines. Pure — testable without the network.
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

    func loadIfNeeded() async {
        switch state {
        case .ready, .loading: return
        default: break
        }
        guard let birthData = store.load() else {
            state = .missingBirthData
            return
        }
        state = .loading
        do {
            // The natal chart is the critical path; transits are best-effort
            // (a missing transit list just hides the "what's happening" rows).
            async let chartLoad = ephemeris.chart(for: birthData)
            async let transitsLoad = ephemeris.transits(for: birthData)
            natalChart = try await chartLoad
            transits = (try? await transitsLoad)?.transits ?? []
            state = .ready
        } catch {
            logger.error("today load failed: \(error.localizedDescription)")
            transits = []
            #if DEBUG
            // Dev builds often run without a Swiss Eph URL; fall back to the
            // sample chart + sample transits so the shell stays exercisable.
            natalChart = BirthChartViewModel.sampleChart()
            transits = Self.sampleTransits()
            state = .ready
            #else
            // In production a real failure must surface, not silently show
            // someone else's chart.
            state = .failed(LuminaError.from(error))
            #endif
        }
    }

    func retry() async {
        state = .idle
        transits = []
        await loadIfNeeded()
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
    #endif
}
