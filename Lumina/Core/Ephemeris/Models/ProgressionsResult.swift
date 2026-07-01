import Foundation

/// Output of `EphemerisService.progressions(for:on:)` — the secondary-progressed
/// chart (day-for-a-year), i.e. how the natal chart has "evolved" to a date.
/// Mirrors `ProgressionsResultSchema` in `backend/src/types.ts`.
struct ProgressionsResult: Codable, Hashable, Sendable {
    let calculatedAt: Date
    /// The target date the progression was computed for.
    let on: Date
    /// The progressed instant (birth + age-in-years days) actually sampled.
    let progressedAt: Date
    /// Progressed positions of all ten bodies.
    let planets: [NatalChart.PlanetPosition]
}
