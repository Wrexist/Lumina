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

    /// The range every birth-date picker in the app must be bounded to.
    ///
    /// Mirrors the backend's `plausibleInstant` schema (1800–2200), which in
    /// turn reflects where `astronomy-engine` is valid. Without a lower bound
    /// the wheel scrolls to year 1, and the request comes back as a generic
    /// server error with nothing telling the user what they did — the picker
    /// should not be able to express a date the service will reject.
    static let selectableBirthDates: ClosedRange<Date> = {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let earliest = utc.date(from: DateComponents(year: 1800, month: 1, day: 1)) ?? .distantPast
        return earliest ... Date.now
    }()

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(birthDate, forKey: .birthDate)
        try container.encode(birthTime, forKey: .birthTime)
        try container.encode(placeName, forKey: .placeName)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(timeZoneIdentifier, forKey: .timeZoneIdentifier)
    }
}
