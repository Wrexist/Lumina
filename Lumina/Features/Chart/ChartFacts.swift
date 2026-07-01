import Foundation

/// Turns a real `NatalChart` into a compact, factual summary for the grounded
/// LLM endpoint (`/interpret`). Pure and unit-tested — the model only ever sees
/// facts that are already true here, never invented placements. This is the
/// grounding contract in one place.
enum ChartFacts {
    /// Cap the aspect list so the prompt stays bounded (the tightest come first).
    private static let maxAspects = 8

    static func summary(of chart: NatalChart) -> String {
        var lines: [String] = []

        for planet in chart.planets {
            let sign = ChartGlyphs.sign(forLongitude: planet.longitude)
            let retro = planet.isRetrograde ? " (retrograde)" : ""
            lines.append("\(planet.planet) in \(sign)\(retro)")
        }

        if let houses = chart.houses {
            lines.append("Ascendant (rising) in \(ChartGlyphs.sign(forLongitude: houses.ascendant))")
            lines.append("Midheaven in \(ChartGlyphs.sign(forLongitude: houses.midheaven))")
        } else {
            lines.append("Birth time unknown — houses, Ascendant, and Midheaven are unavailable.")
        }

        let aspects = chart.aspects.prefix(maxAspects)
        if !aspects.isEmpty {
            lines.append("Aspects:")
            for aspect in aspects {
                lines.append("- \(aspect.planet1) \(aspect.type.rawValue) \(aspect.planet2)")
            }
        }

        return lines.joined(separator: "\n")
    }
}
