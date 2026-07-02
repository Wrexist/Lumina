import Foundation

/// Plain, grounded copy for the secondary-progressed chart — the "chapter"
/// you're living now. The progressed Moon (≈ one sign every 2.5 years) is the
/// most legible marker of an emotional season; the progressed Sun marks a
/// slower shift in identity. Pure and unit-testable. No invented imagery.
enum ProgressedChapter {
    /// "Your progressed Moon is in Scorpio — the emotional season you're moving
    /// through now." Nil when the progressed Moon isn't present.
    static func moonLine(for result: ProgressionsResult) -> String? {
        guard let moon = sign(of: "Moon", in: result) else { return nil }
        return "Your progressed Moon is in \(moon) — the emotional season you're moving through now."
    }

    /// "Progressed Sun in Leo" — the slower shift in how you're growing.
    static func sunLine(for result: ProgressionsResult) -> String? {
        guard let sun = sign(of: "Sun", in: result) else { return nil }
        return "Progressed Sun in \(sun)"
    }

    /// Whether the progressed Moon sits within `orb` degrees of a sign cusp.
    /// The backend exposes no sign-change dates, but the progressed Moon
    /// moves roughly 1° a month, so the default 1.5° flags a sign change
    /// within about the last / next six weeks — the only window the chapter
    /// is timely news rather than slow-moving context. Derived from the real
    /// progressed longitude; nothing invented.
    static func isNearCusp(_ result: ProgressionsResult, orb: Double = 1.5) -> Bool {
        guard let moon = result.planets.first(where: { $0.planet == "Moon" }) else { return false }
        let wrapped = moon.longitude.truncatingRemainder(dividingBy: 360)
        let normalized = wrapped < 0 ? wrapped + 360 : wrapped
        let intoSign = normalized.truncatingRemainder(dividingBy: 30)
        return intoSign < orb || intoSign > 30 - orb
    }

    private static func sign(of planet: String, in result: ProgressionsResult) -> String? {
        result.planets
            .first(where: { $0.planet == planet })
            .map { ChartGlyphs.sign(forLongitude: $0.longitude) }
    }
}
