import Foundation

/// The direction a body takes after its next station. Mirrors
/// `StationDirectionSchema` in `backend/src/types.ts`.
enum StationDirection: String, Codable, Sendable {
    case retrograde
    case direct
}

/// One body's apparent-motion state and its next station. Mirrors
/// `RetrogradeStateSchema` in `backend/src/types.ts`.
struct RetrogradeState: Codable, Hashable, Sendable, Identifiable {
    let planet: String
    let isRetrograde: Bool
    /// The next station instant, or nil if none within the search window.
    let nextStationAt: Date?
    /// The direction the body takes after its next station.
    let nextStationDirection: StationDirection?

    var id: String { planet }
}

/// Output of `EphemerisService.retrogrades(at:)` — which bodies are retrograde
/// now and when each next turns. Global sky data. Mirrors
/// `RetrogradesResultSchema` in `backend/src/types.ts`.
struct RetrogradesResult: Codable, Hashable, Sendable {
    let calculatedAt: Date
    let at: Date
    /// Mercury through Pluto (the Sun and Moon never retrograde).
    let planets: [RetrogradeState]
}
