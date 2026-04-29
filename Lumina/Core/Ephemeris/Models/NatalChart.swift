import Foundation

/// Output of `EphemerisService.chart(for:)`. Field set is intentionally minimal
/// for the bootstrap milestone — extend in Phase 1 with houses, aspects, transits.
struct NatalChart: Codable, Hashable, Sendable {
    struct PlanetPosition: Codable, Hashable, Sendable {
        let planet: String
        let longitude: Double
        let latitude: Double
        let isRetrograde: Bool
    }

    let calculatedAt: Date
    let houseSystem: HouseSystem
    let planets: [PlanetPosition]
}

/// Default is `.placidus` per LEARNINGS.md; UI exposes a toggle.
enum HouseSystem: String, Codable, Sendable, CaseIterable {
    case placidus
    case wholeSign
    case sidereal
}
