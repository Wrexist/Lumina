import Foundation

/// One upcoming moment when a transiting planet's aspect to a natal planet
/// becomes exact — the "timing" layer. Mirrors `ForecastEventSchema` in
/// `backend/src/types.ts`.
struct ForecastEvent: Codable, Hashable, Sendable, Identifiable {
    let transiting: String
    let natal: String
    let type: AspectType
    let exactAngle: Double
    /// The instant the aspect perfects.
    let exactAt: Date

    var id: String { "\(transiting)-\(type.rawValue)-\(natal)-\(exactAt.timeIntervalSince1970)" }
}

/// Output of `EphemerisService.forecast(for:from:days:)`. Mirrors
/// `ForecastResultSchema` in `backend/src/types.ts`.
struct ForecastResult: Codable, Hashable, Sendable {
    let calculatedAt: Date
    let from: Date
    let days: Int
    /// Exact transit moments in the window, earliest first.
    let events: [ForecastEvent]
}
