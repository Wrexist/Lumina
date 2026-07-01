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
    private let ephemeris: EphemerisService
    private let store: UserBirthDataStore

    private(set) var state: LoadState = .idle
    var houseSystem: HouseSystem = .placidus

    init(
        ephemeris: EphemerisService = EphemerisService(),
        store: UserBirthDataStore = .userDefaults
    ) {
        self.ephemeris = ephemeris
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
        let aspects: [NatalChart.Aspect] = [
            .init(planet1: "Sun", planet2: "Moon", type: .square, exactAngle: 90, orb: 5.6),
            .init(planet1: "Mercury", planet2: "Venus", type: .sextile, exactAngle: 60, orb: 2.7),
            .init(planet1: "Venus", planet2: "Mars", type: .trine, exactAngle: 120, orb: 4.3),
            .init(planet1: "Saturn", planet2: "Pluto", type: .trine, exactAngle: 120, orb: 3.9),
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
        case .ready: return
        case .loading: return
        default: break
        }
        await load()
    }

    /// Forces a reload. Called when the house-system picker changes or the
    /// user retries after an error.
    func reload() async {
        state = .idle
        await load()
    }

    private func load() async {
        guard let birthData = store.load() else {
            state = .missingBirthData
            return
        }
        state = .loading
        do {
            let chart = try await ephemeris.chart(for: birthData, houseSystem: houseSystem)
            setReady(chart)
        } catch let serviceError as EphemerisService.ServiceError where serviceError == .missingConfiguration {
            // Dev path — surface a deterministic sample chart so the
            // UI is testable without a backend.
            setReady(BirthChartViewModel.sampleChart())
        } catch {
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
