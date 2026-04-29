import Foundation

/// Captured at onboarding. `birthTime == nil` triggers a "noon-only" chart
/// (houses, Ascendant, MC, DC are hidden) per LEARNINGS.md.
///
/// The encoder always emits `birthTime` as JSON `null` when nil so the
/// backend's `birthTime: z.string().datetime().nullable()` schema accepts
/// it; Swift's default `Encodable` would otherwise omit the key.
struct BirthData: Codable, Hashable, Sendable {
    enum CodingKeys: String, CodingKey {
        case birthDate, birthTime, placeName, latitude, longitude, timeZoneIdentifier
    }

    let birthDate: Date
    let birthTime: Date?
    let placeName: String
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(birthDate, forKey: .birthDate)
        try container.encode(birthTime, forKey: .birthTime)
        try container.encode(placeName, forKey: .placeName)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(timeZoneIdentifier, forKey: .timeZoneIdentifier)
    }
}
