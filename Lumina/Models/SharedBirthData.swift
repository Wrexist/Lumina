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
    var birthDate: Date
    var placeName: String
    var latitude: Double
    var longitude: Double
    var timeZoneIdentifier: String

    init(
        name: String? = nil,
        birthDate: Date,
        placeName: String,
        latitude: Double,
        longitude: Double,
        timeZoneIdentifier: String
    ) {
        self.name = name
        self.birthDate = birthDate
        self.placeName = placeName
        self.latitude = SharedBirthData.coarsen(latitude)
        self.longitude = SharedBirthData.coarsen(longitude)
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    /// Builds a shareable payload from full birth data, dropping the exact
    /// time and coarsening coordinates to city level.
    init(from birthData: BirthData, name: String? = nil) {
        self.init(
            name: name,
            birthDate: birthData.birthDate,
            placeName: birthData.placeName,
            latitude: birthData.latitude,
            longitude: birthData.longitude,
            timeZoneIdentifier: birthData.timeZoneIdentifier
        )
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

    /// Decodes URL-safe base64 (with or without padding).
    init?(base64URLEncoded string: String) {
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
