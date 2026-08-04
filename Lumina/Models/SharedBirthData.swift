import Foundation

/// The deliberately-reduced birth data placed in a shareable QR / `lumina://
/// share/<payload>` URL. We do **not** share exact birth time or precise
/// coordinates — combined with a date those are strongly re-identifying, and a
/// QR on screen can be photographed by anyone. We share the birth date, the
/// city name, a city-level (1-decimal ≈ 11 km) coordinate, and the time zone:
/// enough to add the person and compute sun-sign compatibility, not enough to
/// pinpoint them. See docs/AUDIT-2026-06-03.md R2.
struct SharedBirthData: Codable, Sendable, Hashable {
    var name: String?
    /// The birth day as plain calendar components. Deliberately not a `Date`:
    /// an instant re-interpreted in the recipient's time zone can land on the
    /// neighbouring day, shifting displayed birthdays and cusp sun signs.
    var birthYear: Int
    var birthMonth: Int
    var birthDay: Int
    var placeName: String
    var latitude: Double
    var longitude: Double
    var timeZoneIdentifier: String

    enum CodingKeys: String, CodingKey {
        case name, birthYear, birthMonth, birthDay, birthDate
        case placeName, latitude, longitude, timeZoneIdentifier
    }

    init(
        name: String? = nil,
        birthYear: Int,
        birthMonth: Int,
        birthDay: Int,
        placeName: String,
        latitude: Double,
        longitude: Double,
        timeZoneIdentifier: String
    ) {
        self.name = name
        self.birthYear = birthYear
        self.birthMonth = birthMonth
        self.birthDay = birthDay
        self.placeName = placeName
        self.latitude = SharedBirthData.coarsen(latitude)
        self.longitude = SharedBirthData.coarsen(longitude)
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    /// Builds a shareable payload from full birth data, dropping the exact
    /// time and coarsening coordinates to city level. The calendar day is
    /// read in the birth-place zone, where it is unambiguous.
    init(from birthData: BirthData, name: String? = nil) {
        let parts = BirthMoment.calendar(birthData.timeZoneIdentifier)
            .dateComponents([.year, .month, .day], from: birthData.birthDate)
        self.init(
            name: name,
            birthYear: parts.year ?? 1970,
            birthMonth: parts.month ?? 1,
            birthDay: parts.day ?? 1,
            placeName: birthData.placeName,
            latitude: birthData.latitude,
            longitude: birthData.longitude,
            timeZoneIdentifier: birthData.timeZoneIdentifier
        )
    }

    /// Decodes an **untrusted** payload: this arrives from a scanned QR code or
    /// a `lumina://share/<base64>` URL that anyone can craft. Every field is
    /// range-checked here rather than downstream, so a hostile or corrupt
    /// payload fails as a clean `DecodingError` — "we couldn't read that
    /// code" — instead of producing a plausible-looking chart for month 77 of
    /// year 99999, or a `DateComponents` that silently resolves to
    /// `.distantPast`.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
            .map { String($0.prefix(Self.maxNameLength)) }
        let rawPlace = try container.decode(String.self, forKey: .placeName)
        placeName = String(rawPlace.prefix(Self.maxPlaceNameLength))
        latitude = try Self.validate(
            try container.decode(Double.self, forKey: .latitude),
            in: -90 ... 90, forKey: .latitude, in: container, what: "latitude"
        )
        longitude = try Self.validate(
            try container.decode(Double.self, forKey: .longitude),
            in: -180 ... 180, forKey: .longitude, in: container, what: "longitude"
        )
        let rawZone = try container.decode(String.self, forKey: .timeZoneIdentifier)
        guard TimeZone(identifier: rawZone) != nil else {
            throw DecodingError.dataCorruptedError(
                forKey: .timeZoneIdentifier,
                in: container,
                debugDescription: "unknown time zone identifier"
            )
        }
        timeZoneIdentifier = rawZone
        if let year = try container.decodeIfPresent(Int.self, forKey: .birthYear) {
            // Same bounds the backend enforces on `birthDate`, so a payload
            // that decodes here is one the service will actually accept.
            birthYear = try Self.validate(
                year, in: 1800 ... 2200, forKey: .birthYear, in: container, what: "birth year"
            )
            birthMonth = try Self.validate(
                try container.decode(Int.self, forKey: .birthMonth),
                in: 1 ... 12, forKey: .birthMonth, in: container, what: "birth month"
            )
            birthDay = try Self.validate(
                try container.decode(Int.self, forKey: .birthDay),
                in: 1 ... 31, forKey: .birthDay, in: container, what: "birth day"
            )
        } else {
            // Legacy payload (pre component encoding): an ISO-8601 instant.
            // Best effort — read its day in the shared time zone.
            let legacy = try container.decode(Date.self, forKey: .birthDate)
            let parts = BirthMoment.calendar(timeZoneIdentifier)
                .dateComponents([.year, .month, .day], from: legacy)
            birthYear = try Self.validate(
                parts.year ?? 0, in: 1800 ... 2200, forKey: .birthDate, in: container, what: "birth year"
            )
            birthMonth = parts.month ?? 1
            birthDay = parts.day ?? 1
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(birthYear, forKey: .birthYear)
        try container.encode(birthMonth, forKey: .birthMonth)
        try container.encode(birthDay, forKey: .birthDay)
        try container.encode(placeName, forKey: .placeName)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(timeZoneIdentifier, forKey: .timeZoneIdentifier)
    }

    /// The birth day anchored at noon in the shared time zone — safe to
    /// re-read in any zone that is within 12 hours of the birth place.
    var birthDate: Date {
        var parts = DateComponents(year: birthYear, month: birthMonth, day: birthDay)
        parts.hour = 12
        return BirthMoment.calendar(timeZoneIdentifier).date(from: parts) ?? .distantPast
    }

    /// Reconstructs (coarse) `BirthData` for charting a shared contact. Time
    /// is unknown by design, so the resulting chart is noon / houseless.
    func toBirthData() -> BirthData {
        BirthData(
            birthDate: birthDate,
            birthTime: nil,
            placeName: placeName,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }

    private static func coarsen(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }

    /// Caps on the two free-text fields. A QR payload is size-bounded by the
    /// scanner, but a `lumina://share/<base64>` URL is not, and these strings
    /// are rendered straight into the accept sheet.
    private static let maxNameLength = 60
    private static let maxPlaceNameLength = 200

    private static func validate<T: Comparable>(
        _ value: T,
        in range: ClosedRange<T>,
        forKey key: CodingKeys,
        in container: KeyedDecodingContainer<CodingKeys>,
        what: String
    ) throws -> T {
        guard range.contains(value) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: container,
                debugDescription: "\(what) out of range"
            )
        }
        return value
    }
}

extension JSONEncoder {
    /// Encoder for the share payload — ISO-8601 dates, matched by `luminaShare`
    /// on `JSONDecoder` so the round-trip is symmetric.
    static let luminaShare: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

extension JSONDecoder {
    static let luminaShare: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

extension Data {
    /// URL-safe base64 (RFC 4648 §5) without padding — safe inside a URL path
    /// component, where standard base64's `+` and `/` are not.
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// The largest share payload we will even attempt to decode.
    ///
    /// A real `SharedBirthData` is a few hundred bytes. The cap exists because
    /// the input is a URL anyone can construct: without it, a multi-megabyte
    /// `lumina://share/<...>` would be base64-decoded and JSON-parsed in full
    /// on the main thread before any of the field validation could reject it.
    static let maxSharePayloadBytes = 4096

    /// Decodes URL-safe base64 (with or without padding), refusing anything
    /// implausibly large for a share payload.
    init?(base64URLEncoded string: String) {
        guard string.utf8.count <= Data.maxSharePayloadBytes else { return nil }
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        self.init(base64Encoded: base64)
    }
}
