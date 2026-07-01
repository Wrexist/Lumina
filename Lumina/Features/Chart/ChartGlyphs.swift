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
        textPresented(rawPlanetGlyph(name))
    }

    private static func rawPlanetGlyph(_ name: String) -> String {
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

    /// Forces monochrome **text** presentation (U+FE0E) so a glyph renders in
    /// the brand ink/gold colour, never as the OS's colour-emoji tile. The
    /// zodiac signs (U+2648–2653) default to emoji presentation otherwise.
    /// DECISION: Lumina uses premium editorial type — never emoji.
    private static func textPresented(_ glyph: String) -> String {
        glyph == "•" ? glyph : glyph + "\u{FE0E}"
    }

    /// Sign at the given ecliptic longitude (0–360°).
    static func sign(forLongitude longitude: Double) -> String {
        let normalised = (longitude.truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360)
        let index = Int(normalised / 30) % 12
        return signOrder[index]
    }

    static func signGlyph(_ name: String) -> String {
        textPresented(rawSignGlyph(name))
    }

    private static func rawSignGlyph(_ name: String) -> String {
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
            return "\(degree)° \(sign) \(signGlyph) · \(ordinal(house)) house"
        }
        return "\(degree)° \(sign) \(signGlyph)"
    }

    /// English ordinal — "1st", "2nd", "3rd", "4th"… (fixes the "1th house" bug).
    static func ordinal(_ number: Int) -> String {
        let ones = number % 10
        let tens = (number / 10) % 10
        let suffix: String
        if tens == 1 {
            suffix = "th"
        } else if ones == 1 {
            suffix = "st"
        } else if ones == 2 {
            suffix = "nd"
        } else if ones == 3 {
            suffix = "rd"
        } else {
            suffix = "th"
        }
        return "\(number)\(suffix)"
    }

    static let signOrder: [String] = [
        "Aries", "Taurus", "Gemini", "Cancer",
        "Leo", "Virgo", "Libra", "Scorpio",
        "Sagittarius", "Capricorn", "Aquarius", "Pisces",
    ]
}
