import Foundation

/// Maps an ecliptic longitude (0–360°) to the Human Design gate it falls
/// in. Each gate covers exactly 5°37'30" (5.625°), and the wheel is
/// rotated so Gate 25 begins at 28°15'00" Pisces (= 358.25°, i.e. −1.75°)
/// and ends at 3°52'30" Aries — so 0° Aries itself falls inside Gate 25.
///
/// The 64-gate sequence around the zodiac is fixed by the I Ching →
/// Mandala mapping; we ship it as a literal array so any reviewer can
/// verify against any HD reference (myBodyGraph, Jovian Archive, etc.).
///
/// **What's real here**: gate calculation from a single longitude.
/// **What's NOT here yet**: the design-side "88° solar arc" chart that
/// HD also requires. That ships when the backend exposes a /design
/// endpoint (ROADMAP.md Phase 8 finish-line).
enum HumanDesignMandala {
    /// Width of one gate in degrees of ecliptic longitude.
    static let gateWidth = 5.625

    /// Offset of Gate 25's leading edge from 0° Aries, in degrees.
    /// Gate 25 *ends* at 3°52'30" Aries; it *begins* one gate-width
    /// earlier, at 28°15'00" Pisces = 358.25° = −1.75°.
    static let zeroOffset = -1.75

    /// Gate sequence in zodiacal order from the leading edge of Gate 25
    /// at 28°15'00" Pisces, then walking counter-clockwise around the
    /// wheel through the 12 signs. Index 0 is Gate 25 itself.
    static let sequence: [Int] = [
        25, 17, 21, 51, 42, 3,
        27, 24, 2, 23, 8, 20,
        16, 35, 45, 12, 15, 52,
        39, 53, 62, 56, 31, 33,
        7, 4, 29, 59, 40, 64,
        47, 6, 46, 18, 48, 57,
        32, 50, 28, 44, 1, 43,
        14, 34, 9, 5, 26, 11,
        10, 58, 38, 54, 61, 60,
        41, 19, 13, 49, 30, 55,
        37, 63, 22, 36,
    ]

    /// Returns the gate (1–64) for the given ecliptic longitude.
    /// Wraps around 360°.
    static func gate(forLongitude longitude: Double) -> Int {
        let normalised = (longitude.truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360)
        let shifted = (normalised - zeroOffset + 360)
            .truncatingRemainder(dividingBy: 360)
        let index = Int(shifted / gateWidth) % sequence.count
        return sequence[index]
    }

    /// Returns the line (1–6) within the gate for the given longitude.
    /// Each gate is divided into six equal lines of 0.9375° each.
    static func line(forLongitude longitude: Double) -> Int {
        let normalised = (longitude.truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360)
        let shifted = (normalised - zeroOffset + 360)
            .truncatingRemainder(dividingBy: 360)
        let withinGate = shifted.truncatingRemainder(dividingBy: gateWidth)
        let line = Int(withinGate / (gateWidth / 6)) + 1
        return min(6, max(1, line))
    }
}
