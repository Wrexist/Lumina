import Foundation

/// The questions a user can ask their chart. Curated (not free-text) so every
/// answer is deterministic and grounded — the honest, unblocked version of
/// "ask your chart". A language model later turns this into open conversation,
/// but the answers can only ever restate facts that are already true here.
enum ChartQuestion: String, CaseIterable, Identifiable, Sendable {
    case bigThree = "What are my Big 3?"
    case strongestAspect = "What's my strongest aspect?"
    case dominantElement = "What's my dominant element?"
    case retrogrades = "Which of my planets are retrograde?"
    case focalPlanet = "What stands out in my chart?"

    var id: String { rawValue }
}

/// Answers `ChartQuestion`s straight from a real `NatalChart` — no language
/// model, no hallucination. Reuses the same grounded building blocks as the
/// `PlacementInterpreter` / `AspectInterpreter`.
enum ChartOracle {
    static func answer(to question: ChartQuestion, chart: NatalChart) -> String {
        switch question {
        case .bigThree: bigThree(chart)
        case .strongestAspect: strongestAspect(chart)
        case .dominantElement: dominantElement(chart)
        case .retrogrades: retrogrades(chart)
        case .focalPlanet: focalPlanet(chart)
        }
    }

    // MARK: - Answers

    private static func bigThree(_ chart: NatalChart) -> String {
        let sun = position("Sun", chart).map { ChartGlyphs.sign(forLongitude: $0.longitude) }
        let moon = position("Moon", chart).map { ChartGlyphs.sign(forLongitude: $0.longitude) }
        let rising = chart.houses.map { ChartGlyphs.sign(forLongitude: $0.ascendant) }

        var parts: [String] = []
        if let sun { parts.append("a \(sun) Sun") }
        if let moon { parts.append("a \(moon) Moon") }
        if let rising { parts.append("\(rising) rising") }
        guard !parts.isEmpty else { return "Your chart is still loading." }

        let tail = rising == nil
            ? " Add your birth time to reveal your rising sign too."
            : ""
        return "You have \(parts.joined(separator: ", ")). Together they're the quickest read on "
            + "who you are — your core, your heart, and the face you lead with.\(tail)"
    }

    private static func strongestAspect(_ chart: NatalChart) -> String {
        guard let aspect = chart.aspects.first else {
            return "Your planets sit largely on their own right now — no tight major aspects to call out."
        }
        return AspectInterpreter.interpretation(
            planet1: aspect.planet1, planet2: aspect.planet2, type: aspect.type
        ) + " It's your tightest aspect, so it colours a lot of how you operate."
    }

    private static func dominantElement(_ chart: NatalChart) -> String {
        var counts: [String: Int] = [:]
        for planet in chart.planets {
            counts[element(of: ChartGlyphs.sign(forLongitude: planet.longitude)), default: 0] += 1
        }
        guard let top = counts.max(by: { $0.value < $1.value }) else {
            return "Your chart is still loading."
        }
        return "Your chart leans \(top.key) — \(elementMeaning(top.key)) With \(top.value) of your ten "
            + "planets there, it's a real throughline."
    }

    private static func retrogrades(_ chart: NatalChart) -> String {
        let retro = chart.planets.filter { $0.isRetrograde }.map(\.planet)
        guard !retro.isEmpty else {
            return "None of your planets are retrograde — your energies tend to move forward directly."
        }
        let verb = retro.count == 1 ? "is" : "are"
        return "\(retro.joined(separator: ", ")) \(verb) retrograde in your chart — areas you tend to "
            + "turn inward on, revisiting and refining rather than broadcasting."
    }

    private static func focalPlanet(_ chart: NatalChart) -> String {
        var counts: [String: Int] = [:]
        for aspect in chart.aspects {
            counts[aspect.planet1, default: 0] += 1
            counts[aspect.planet2, default: 0] += 1
        }
        guard let top = counts.max(by: { $0.value < $1.value }), top.value > 0 else {
            return "No single planet dominates your aspects — your chart is fairly evenly woven."
        }
        return "Your \(top.key) is a focal point — it's tied into \(top.value) of your major aspects, "
            + "so it pulls a lot of your chart together."
    }

    // MARK: - Helpers

    private static func position(_ name: String, _ chart: NatalChart) -> NatalChart.PlanetPosition? {
        chart.planets.first { $0.planet == name }
    }

    private static func element(of sign: String) -> String {
        switch sign {
        case "Aries", "Leo", "Sagittarius": "fire"
        case "Taurus", "Virgo", "Capricorn": "earth"
        case "Gemini", "Libra", "Aquarius": "air"
        default: "water"
        }
    }

    private static func elementMeaning(_ element: String) -> String {
        switch element {
        case "fire": "drive, warmth, and a need to act."
        case "earth": "groundedness, the senses, and getting real things done."
        case "air": "ideas, words, and connection."
        default: "feeling, intuition, and depth."
        }
    }
}
