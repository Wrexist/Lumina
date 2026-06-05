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

    private static func sign(of planet: String, in result: ProgressionsResult) -> String? {
        result.planets
            .first(where: { $0.planet == planet })
            .map { ChartGlyphs.sign(forLongitude: $0.longitude) }
    }
}
