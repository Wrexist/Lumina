import Foundation
import OSLog

/// View model for the Chart tab. Reads the persisted `BirthData`, calls
/// `EphemerisService` to produce a `NatalChart`, exposes loading + error
/// state for the View.
///
/// Phase 4 of the roadmap stays minimal here — Phase 5 hooks RAG-backed
/// interpretations into `interpretation(for:)` and similar.
@MainActor
@Observable
final class BirthChartViewModel {
    enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case ready(NatalChart)
        case missingBirthData
        case failed(LuminaError)
    }

    private let logger = Logger(subsystem: "app.lumina.ios", category: "BirthChartViewModel")
    private let chartCache: ChartCache
    private let store: UserBirthDataStore

    private(set) var state: LoadState = .idle
    /// Backed by `AppPreferences` so the choice survives a relaunch. This was
    /// view-model-only state, which meant Whole-sign and Sidereal silently
    /// reset to Placidus every cold launch.
    var houseSystem: HouseSystem {
        get { AppPreferences.shared.houseSystem }
        set { AppPreferences.shared.houseSystem = newValue }
    }

    /// The in-flight load, kept so a newer request can cancel it — a rapid
    /// house-system switch must never let a stale response overwrite `state`.
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    /// What the ready chart was loaded against — `loadIfNeeded()` reloads when
    /// either moves (birth info edited in Settings, or the calendar day rolled
    /// over in a long-lived process), so the Chart tab and the widget never go
    /// stale after a Settings edit. Mirrors `TodayViewModel`.
    private var loadedRevision: Int?
    private var loadedDay: Date?

    init(
        chartCache: ChartCache = .shared,
        store: UserBirthDataStore = .userDefaults
    ) {
        self.chartCache = chartCache
        self.store = store
    }

    /// Deterministic sample chart for previews and dev builds without
    /// the Swiss Eph URL configured. Stockholm 1990-06-15 14:30 — values
    /// approximate, not astronomically precise.
    static func sampleChart() -> NatalChart {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let calculatedAt = formatter.date(from: "2026-05-08T00:00:00.000Z") ?? Date()
        let planets: [NatalChart.PlanetPosition] = [
            .init(planet: "Sun", longitude: 84.15, latitude: 0.0, isRetrograde: false),
            .init(planet: "Moon", longitude: 345.64, latitude: 3.15, isRetrograde: false),
            .init(planet: "Mercury", longitude: 65.73, latitude: -1.66, isRetrograde: false),
            .init(planet: "Venus", longitude: 102.4, latitude: 0.5, isRetrograde: false),
            .init(planet: "Mars", longitude: 28.1, latitude: 0.2, isRetrograde: false),
            .init(planet: "Jupiter", longitude: 110.9, latitude: 0.3, isRetrograde: false),
            .init(planet: "Saturn", longitude: 290.4, latitude: -0.4, isRetrograde: true),
            .init(planet: "Uranus", longitude: 280.8, latitude: -0.1, isRetrograde: true),
            .init(planet: "Neptune", longitude: 285.7, latitude: 0.6, isRetrograde: true),
            .init(planet: "Pluto", longitude: 226.5, latitude: 5.4, isRetrograde: true),
        ]
        // Sorted by orb ascending (tightest first) — `ChartOracle` and
        // `StrongestAspectsCard` rely on that ordering, matching the server.
        let aspects: [NatalChart.Aspect] = [
            .init(planet1: "Mercury", planet2: "Venus", type: .sextile, exactAngle: 60, orb: 2.7),
            .init(planet1: "Saturn", planet2: "Pluto", type: .trine, exactAngle: 120, orb: 3.9),
            .init(planet1: "Venus", planet2: "Mars", type: .trine, exactAngle: 120, orb: 4.3),
            .init(planet1: "Sun", planet2: "Moon", type: .square, exactAngle: 90, orb: 5.6),
        ]
        let houses = NatalChart.HouseCusps(
            system: .placidus,
            ascendant: 192.01,
            midheaven: 106.73,
            cusps: [192.01, 220.5, 252.7, 286.73, 320.5, 350.0, 12.01, 40.5, 72.7, 106.73, 140.5, 170.0]
        )
        return NatalChart(
            calculatedAt: calculatedAt,
            houseSystem: .placidus,
            planets: planets,
            aspects: aspects,
            houses: houses
        )
    }

    /// Loads the chart. Idempotent — safe to call from `.task`. Reuses
    /// the existing chart when the house system hasn't changed.
    func loadIfNeeded() async {
        switch state {
        case .loading: return
        case .ready where contentIsFresh: return
        default: break
        }
        await startLoad()
    }

    /// The ready chart is still current unless the birth data was edited in
    /// Settings or the calendar day rolled over since we loaded.
    private var contentIsFresh: Bool {
        guard loadedRevision == store.revision, let loadedDay else { return false }
        return Calendar.current.isDate(loadedDay, inSameDayAs: .now)
    }

    /// Forces a reload. Called when the house-system picker changes or the
    /// user retries after an error.
    func reload() async {
        state = .idle
        await startLoad()
    }

    /// Cancels any in-flight load before starting a new one, so the newest
    /// request always wins — without this, rapid house-system switches could
    /// let a stale response land last and overwrite the chart.
    private func startLoad() async {
        loadTask?.cancel()
        let task = Task { await load() }
        loadTask = task
        await task.value
    }

    private func load() async {
        guard let birthData = store.load() else {
            state = .missingBirthData
            return
        }
        loadedRevision = store.revision
        loadedDay = .now
        state = .loading
        do {
            let chart = try await chartCache.chart(for: birthData, houseSystem: houseSystem)
            guard !Task.isCancelled else { return }
            setReady(chart)
        } catch is CancellationError {
            // Superseded by a newer load — its result owns `state` now.
        } catch let serviceError as EphemerisService.ServiceError where serviceError == .missingConfiguration {
            guard !Task.isCancelled else { return }
            #if DEBUG
            // Dev path — surface a deterministic sample chart so the UI is
            // testable without a backend. Deliberately NOT pushed to the
            // widget: fake data must never reach the home screen.
            state = .ready(BirthChartViewModel.sampleChart())
            #else
            // Release must never render a fabricated chart as the user's own —
            // an unconfigured backend fails honestly, like every other surface.
            state = .failed(LuminaError.from(serviceError))
            #endif
        } catch {
            guard !Task.isCancelled else { return }
            logger.error("chart load failed: \(error.localizedDescription)")
            state = .failed(LuminaError.from(error))
        }
    }

    /// Moves to `.ready` and refreshes the home-screen widget from the same
    /// chart, so the widget's Big-3 always reflects the latest computed chart
    /// without needing its own network call.
    private func setReady(_ chart: NatalChart) {
        state = .ready(chart)
        WidgetPublisher.publish(from: chart)
    }
}
