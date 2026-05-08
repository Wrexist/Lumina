import Foundation

/// Output of `EphemerisService.chart(for:)`. Mirrors `NatalChartSchema`
/// in `backend/src/types.ts` 1:1.
struct NatalChart: Codable, Hashable, Sendable {
    struct PlanetPosition: Codable, Hashable, Sendable {
        let planet: String
        let longitude: Double
        let latitude: Double
        let isRetrograde: Bool
    }

    /// `houses` is `null` when the birth time is unknown — Asc, MC, and
    /// the 12 cusps are meaningless without it.
    struct HouseCusps: Codable, Hashable, Sendable {
        let system: HouseSystem
        let ascendant: Double
        let midheaven: Double
        let cusps: [Double]
    }

    /// One of the five major Ptolemaic aspects between two natal planets.
    /// `exactAngle` is the canonical aspect angle (0, 60, 90, 120, 180);
    /// `orb` is the absolute deviation from that exact angle.
    struct Aspect: Codable, Hashable, Sendable {
        let planet1: String
        let planet2: String
        let type: AspectType
        let exactAngle: Double
        let orb: Double
    }

    let calculatedAt: Date
    let houseSystem: HouseSystem
    let planets: [PlanetPosition]
    let aspects: [Aspect]
    let houses: HouseCusps?
}

/// Default is `.placidus` per LEARNINGS.md; UI exposes a toggle.
enum HouseSystem: String, Codable, Sendable, CaseIterable {
    case placidus
    case wholeSign
    case sidereal
}

/// The five major Ptolemaic aspects.
enum AspectType: String, Codable, Sendable, CaseIterable {
    case conjunction
    case sextile
    case square
    case trine
    case opposition
}
