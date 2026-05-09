import Foundation
import OSLog

/// View model for the Today (Home) tab. Loads the user's natal chart so
/// the Big 3 band, "your sky today" headline, and the quick-actions row
/// can render against real placements.
///
/// Real RAG-backed reading body + ElevenLabs audio land with Phase 3/5 of
/// `ROADMAP.md`. Until then, the today-reading state surfaces the
/// canonical "needs Anthropic key" affordance.
@MainActor
@Observable
final class TodayViewModel {
    enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case ready
        case missingBirthData
    }

    static let pool: [String] = [
        "Mercury squares Saturn — words feel heavier than usual.",
        "The Moon enters a tender water sign tonight — slow down for it.",
        "Venus settles into routine — small acts of care over grand gestures.",
        "Mars asks where your time actually goes today.",
        "A trine between Sun and Jupiter widens what's possible.",
        "Saturn holds the line on something half-finished.",
        "Mercury and Venus meet — clearer words around what you want.",
        "The Moon waxes — what wants to be said, said it now.",
        "Pluto retraces familiar ground — note what's changed since last time.",
        "Uranus shakes a small assumption loose. Don't refasten it too quickly.",
    ]

    private let logger = Logger(subsystem: "app.lumina.ios", category: "TodayViewModel")
    private let store: UserBirthDataStore
    private let ephemeris: EphemerisService

    private(set) var state: LoadState = .idle
    private(set) var natalChart: NatalChart?

    init(
        store: UserBirthDataStore = .userDefaults,
        ephemeris: EphemerisService = EphemerisService()
    ) {
        self.store = store
        self.ephemeris = ephemeris
    }

    /// Headline transit for the day. Deterministic per local day so the
    /// Today screen, the morning push (Phase 11), and the journal prompt
    /// (Phase 9) can all reference the same line.
    static func headline(for date: Date, calendar: Calendar = .current) -> String {
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
        return pool[day % pool.count]
    }

    /// Three "what's happening in your sky" rows. Deterministic per day,
    /// non-overlapping. Phase 5 swaps to real top-3 transits from the
    /// backend `/transits` endpoint.
    static func whatsHappening(for date: Date, calendar: Calendar = .current) -> [String] {
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
        let primary = pool[day % pool.count]
        let secondary = pool[(day + 3) % pool.count]
        let tertiary = pool[(day + 7) % pool.count]
        return [primary, secondary, tertiary]
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
            natalChart = try await ephemeris.chart(for: birthData)
            state = .ready
        } catch let serviceError as EphemerisService.ServiceError where serviceError == .missingConfiguration {
            // Dev path — let the Today screen still render against the
            // sample chart so the rest of the shell is exercised.
            natalChart = BirthChartViewModel.sampleChart()
            state = .ready
        } catch {
            logger.error("today chart load failed: \(error.localizedDescription)")
            // Fall back to sample so Today never dead-ends. Real error
            // surfacing happens on Chart tab where a retry exists.
            natalChart = BirthChartViewModel.sampleChart()
            state = .ready
        }
    }
}
