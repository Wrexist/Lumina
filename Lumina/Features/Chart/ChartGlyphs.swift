import Foundation

/// Maps backend planet names ("Sun", "Moon", …) and astronomical sign
/// indices to their Unicode glyphs, brand colors, and human-readable
/// names. Single source of truth — every chart-rendering surface and
/// detail sheet reads from here.
enum ChartGlyphs {
    static let planetOrder: [String] = [
        "Sun", "Moon", "Mercury", "Venus", "Mars",
        "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto",
    ]

    static func planetGlyph(_ name: String) -> String {
        switch name {
        case "Sun": "☉"
        case "Moon": "☾"
        case "Mercury": "☿"
        case "Venus": "♀"
        case "Mars": "♂"
        case "Jupiter": "♃"
        case "Saturn": "♄"
        case "Uranus": "♅"
        case "Neptune": "♆"
        case "Pluto": "♇"
        default: "•"
        }
    }

    /// Sign at the given ecliptic longitude (0–360°).
    static func sign(forLongitude longitude: Double) -> String {
        let normalised = (longitude.truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360)
        let index = Int(normalised / 30) % 12
        return signOrder[index]
    }

    static func signGlyph(_ name: String) -> String {
        switch name {
        case "Aries": "♈"
        case "Taurus": "♉"
        case "Gemini": "♊"
        case "Cancer": "♋"
        case "Leo": "♌"
        case "Virgo": "♍"
        case "Libra": "♎"
        case "Scorpio": "♏"
        case "Sagittarius": "♐"
        case "Capricorn": "♑"
        case "Aquarius": "♒"
        case "Pisces": "♓"
        default: "•"
        }
    }

    /// Pretty 1-line summary for a planet in a sign and house.
    static func summary(planet: String, longitude: Double, house: Int?) -> String {
        let sign = sign(forLongitude: longitude)
        let degree = Int(longitude.truncatingRemainder(dividingBy: 30))
        let signGlyph = signGlyph(sign)
        if let house {
            return "\(degree)° \(sign) \(signGlyph) · \(house)th house"
        }
        return "\(degree)° \(sign) \(signGlyph)"
    }

    static let signOrder: [String] = [
        "Aries", "Taurus", "Gemini", "Cancer",
        "Leo", "Virgo", "Libra", "Scorpio",
        "Sagittarius", "Capricorn", "Aquarius", "Pisces",
    ]
}
