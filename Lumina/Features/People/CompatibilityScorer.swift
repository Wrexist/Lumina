import Foundation

/// Deterministic compatibility scorer. Phase-7 of `ROADMAP.md` brings
/// real synastry math via the backend; until that endpoint ships, this
/// produces a stable 0–100 score from the two birth dates so the People
/// tab can display something meaningful end-to-end.
///
/// Properties of the algorithm:
///   * Symmetric — `score(a, b) == score(b, a)`
///   * Stable — same pair always returns the same score
///   * Element-aware — same-element Sun signs nudge up; opposite signs
///     nudge down. Modality match adds a smaller nudge.
///
/// Replace the `score(...)` body with the synastry-aspect-weighted
/// algorithm once `/synastry` lands. The signature stays the same so
/// callers don't move.
enum CompatibilityScorer {
    enum Element: String, CaseIterable, Sendable {
        case fire
        case earth
        case air
        case water
    }

    enum Modality: String, CaseIterable, Sendable {
        case cardinal
        case fixed
        case mutable
    }

    enum Label: String, Sendable {
        case magnetic
        case harmonious
        case stimulating
        case challenging

        var displayName: String {
            switch self {
            case .magnetic: "Magnetic"
            case .harmonious: "Harmonious"
            case .stimulating: "Stimulating"
            case .challenging: "Challenging"
            }
        }

        init(score: Int) {
            switch score {
            case 80...: self = .magnetic
            case 60..<80: self = .harmonious
            case 40..<60: self = .stimulating
            default: self = .challenging
            }
        }
    }

    /// Returns a 0–100 score from two birth dates. Symmetric.
    static func score(_ left: Date, _ right: Date, calendar: Calendar = .current) -> Int {
        let leftSign = sunSign(for: left, calendar: calendar)
        let rightSign = sunSign(for: right, calendar: calendar)
        let leftElement = element(for: leftSign)
        let rightElement = element(for: rightSign)
        let leftModality = modality(for: leftSign)
        let rightModality = modality(for: rightSign)

        var score = 50
        score += elementBonus(leftElement, rightElement)
        score += modalityBonus(leftModality, rightModality)
        // A small deterministic-but-symmetric jitter so different sign
        // pairs in the same element/modality bucket don't all land on
        // the same number. Hashes are order-independent because we sort.
        let pair = [leftSign, rightSign].sorted()
        let jitter = Int(stableHash("\(pair[0])-\(pair[1])") % 11) - 5
        score += jitter
        return max(0, min(100, score))
    }

    /// FNV-1a 64-bit hash — deterministic across processes. `String.hashValue`
    /// is seeded per app run, so using it here drifted the cached
    /// `Friend.compatibilityScore` on every cold launch.
    static func stableHash(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return hash
    }

    /// Combined sun-sign string for display ("Aries · Leo").
    static func summary(for left: Date, _ right: Date, calendar: Calendar = .current) -> String {
        let a = sunSign(for: left, calendar: calendar)
        let b = sunSign(for: right, calendar: calendar)
        return "\(a) · \(b)"
    }

    // MARK: - Private helpers

    /// Approximate Sun-sign by birth-date day of year. Boundaries align
    /// with the standard Western tropical zodiac to within a day or two.
    private static func sunSign(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.month, .day], from: date)
        let month = components.month ?? 1
        let day = components.day ?? 1
        switch (month, day) {
        case (3, 21...), (4, ...19): return "Aries"
        case (4, 20...), (5, ...20): return "Taurus"
        case (5, 21...), (6, ...20): return "Gemini"
        case (6, 21...), (7, ...22): return "Cancer"
        case (7, 23...), (8, ...22): return "Leo"
        case (8, 23...), (9, ...22): return "Virgo"
        case (9, 23...), (10, ...22): return "Libra"
        case (10, 23...), (11, ...21): return "Scorpio"
        case (11, 22...), (12, ...21): return "Sagittarius"
        case (12, 22...), (1, ...19): return "Capricorn"
        case (1, 20...), (2, ...18): return "Aquarius"
        default: return "Pisces"
        }
    }

    private static func element(for sign: String) -> Element {
        switch sign {
        case "Aries", "Leo", "Sagittarius": .fire
        case "Taurus", "Virgo", "Capricorn": .earth
        case "Gemini", "Libra", "Aquarius": .air
        default: .water
        }
    }

    private static func modality(for sign: String) -> Modality {
        switch sign {
        case "Aries", "Cancer", "Libra", "Capricorn": .cardinal
        case "Taurus", "Leo", "Scorpio", "Aquarius": .fixed
        default: .mutable
        }
    }

    private static func elementBonus(_ a: Element, _ b: Element) -> Int {
        if a == b { return 22 }
        switch (a, b) {
        case (.fire, .air), (.air, .fire), (.earth, .water), (.water, .earth): return 14
        case (.fire, .water), (.water, .fire), (.earth, .air), (.air, .earth): return -8
        default: return 0
        }
    }

    private static func modalityBonus(_ a: Modality, _ b: Modality) -> Int {
        a == b ? 6 : 0
    }
}
