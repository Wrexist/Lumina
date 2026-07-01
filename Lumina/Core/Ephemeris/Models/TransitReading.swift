import Foundation

/// One transiting (currently-moving) planet's aspect to a natal planet —
/// "transiting Mars trine your natal Venus". Mirrors `TransitSchema` in
/// `backend/src/types.ts` 1:1.
struct TransitReading: Codable, Hashable, Sendable, Identifiable {
    /// The currently-moving planet making the contact.
    let transiting: String
    /// The natal planet being contacted.
    let natal: String
    let type: AspectType
    let exactAngle: Double
    /// Absolute deviation from the exact aspect angle, in degrees.
    let orb: Double
    /// True when the aspect is tightening toward exact, false when separating.
    let applying: Bool

    /// Stable identity for SwiftUI lists. A given transit result holds at
    /// most one aspect per (transiting, natal) pair, so the triple is unique.
    var id: String { "\(transiting)-\(type.rawValue)-\(natal)" }
}

/// Output of `EphemerisService.transits(for:at:)`. Mirrors
/// `TransitsResultSchema` in `backend/src/types.ts` 1:1.
struct TransitsResult: Codable, Hashable, Sendable {
    let calculatedAt: Date
    /// The moment the transiting positions were computed for.
    let transitAt: Date
    /// Current geocentric positions of all ten bodies.
    let transitingPlanets: [NatalChart.PlanetPosition]
    /// Transit→natal aspects, sorted ascending by orb (tightest first).
    let transits: [TransitReading]
}
