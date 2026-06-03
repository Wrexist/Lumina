import Foundation

/// One cross-aspect between two people's charts — "your Venus conjunct
/// their Mars". Mirrors `SynastryAspectSchema` in `backend/src/types.ts`.
struct SynastryAspect: Codable, Hashable, Sendable, Identifiable {
    /// The viewer's ("your") planet.
    let planetA: String
    /// The other person's ("their") planet.
    let planetB: String
    let type: AspectType
    let exactAngle: Double
    /// Absolute deviation from the exact aspect angle, in degrees.
    let orb: Double

    /// Stable identity for SwiftUI lists — one aspect per (A, B) pair.
    var id: String { "\(planetA)-\(type.rawValue)-\(planetB)" }
}

/// Output of `EphemerisService.synastry(personA:personB:)`. Mirrors
/// `SynastryResultSchema` in `backend/src/types.ts`.
struct SynastryResult: Codable, Hashable, Sendable {
    let calculatedAt: Date
    /// A↔B cross-aspects, sorted ascending by orb (tightest first).
    let aspects: [SynastryAspect]
}

/// One person in a `POST /synastry` request. Geocentric planet longitudes
/// don't depend on birth place, so only the date (+ optional time/zone) is
/// sent. Nil fields are *omitted* (the backend treats them as optional, not
/// nullable).
struct SynastryPerson: Encodable, Sendable {
    let birthDate: Date
    let birthTime: Date?
    let timeZoneIdentifier: String?

    enum CodingKeys: String, CodingKey {
        case birthDate
        case birthTime
        case timeZoneIdentifier
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(birthDate, forKey: .birthDate)
        try container.encodeIfPresent(birthTime, forKey: .birthTime)
        try container.encodeIfPresent(timeZoneIdentifier, forKey: .timeZoneIdentifier)
    }
}
