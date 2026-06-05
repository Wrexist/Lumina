import Foundation

/// Output of `EphemerisService.composite(personA:personB:)`. The composite
/// (midpoint) chart merges two people into a single relationship chart — each
/// planet sits at the shorter-arc midpoint of the pair, then the same aspect
/// engine runs over the merged set. Mirrors `CompositeResultSchema` in
/// `backend/src/types.ts`. Reuses `NatalChart`'s nested DTOs since the shape
/// is identical to a single chart's planets + aspects.
struct CompositeResult: Codable, Hashable, Sendable {
    let calculatedAt: Date
    /// Composite planets (midpoints of the two charts).
    let planets: [NatalChart.PlanetPosition]
    /// Major aspects within the composite chart, sorted ascending by orb.
    let aspects: [NatalChart.Aspect]
}
