import Foundation

/// One upcoming planetary return — when a slow planet next comes back to its
/// natal longitude (the Saturn return at ~29, the Jupiter return every ~12).
/// Mirrors `ReturnEventSchema` in `backend/src/types.ts`.
struct ReturnEvent: Codable, Hashable, Sendable, Identifiable {
    /// "Jupiter" or "Saturn".
    let planet: String
    /// Which return this is — 1 = first, 2 = second, …
    let returnNumber: Int
    /// The instant the return perfects.
    let exactAt: Date
    /// The natal longitude the planet returns to.
    let natalLongitude: Double

    var id: String { "\(planet)-\(returnNumber)" }
}

/// Output of `EphemerisService.returns(for:from:)` — upcoming Jupiter and
/// Saturn returns. Mirrors `ReturnsResultSchema` in `backend/src/types.ts`.
struct ReturnsResult: Codable, Hashable, Sendable {
    let calculatedAt: Date
    let from: Date
    /// Next Jupiter and Saturn returns, sorted earliest first.
    let events: [ReturnEvent]
}
