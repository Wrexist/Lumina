import Foundation

/// Output of `EphemerisService.chart(for:)`. Mirrors `NatalChartSchema`
/// in `backend/src/types.ts` 1:1.
struct NatalChart: Codable, Hashable, Sendable {
    struct PlanetPosition: Codable, Hashable, Sendable {
        let planet: String
        let longitude: Double
        let latitude: Double
        let isRetrograde: Bool

        init(planet: String, longitude: Double, latitude: Double, isRetrograde: Bool) {
            self.planet = planet
            self.longitude = longitude
            self.latitude = latitude
            self.isRetrograde = isRetrograde
        }

        /// Rejects non-finite angles at the boundary.
        ///
        /// `Int(someDouble)` traps on NaN and infinity, and the chart wheel
        /// converts server-supplied longitudes for its accessibility labels.
        /// The backend can't emit either today — `houses.ts` guards
        /// circumpolar geometry — but that's one regression away from a hard
        /// crash on the app's main screen. A `DecodingError` here surfaces as
        /// "we couldn't read the server's response", which is both true and
        /// survivable; a trap is neither.
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            planet = try container.decode(String.self, forKey: .planet)
            let rawLongitude = try container.decode(Double.self, forKey: .longitude)
            let rawLatitude = try container.decode(Double.self, forKey: .latitude)
            longitude = try Self.finite(rawLongitude, forKey: .longitude, in: container)
            latitude = try Self.finite(rawLatitude, forKey: .latitude, in: container)
            isRetrograde = try container.decode(Bool.self, forKey: .isRetrograde)
        }

        private static func finite(
            _ value: Double,
            forKey key: CodingKeys,
            in container: KeyedDecodingContainer<CodingKeys>
        ) throws -> Double {
            guard value.isFinite else {
                throw DecodingError.dataCorruptedError(
                    forKey: key,
                    in: container,
                    debugDescription: "\(key.stringValue) must be finite, got \(value)"
                )
            }
            return value
        }
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
