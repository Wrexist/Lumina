import Foundation

/// A shareable, at-a-glance "cosmic signature" from the real chart: the Big 3,
/// the dominant element and modality (weighted toward the luminaries + rising),
/// and a one-line headline. Pure and unit-testable — the same grounded facts
/// the app already shows, packaged for identity and sharing (the category's
/// biggest premium-safe growth lever; see `docs/VIRALITY.md`).
struct CosmicSignature: Equatable, Sendable {
    let sunSign: String?
    let moonSign: String?
    let risingSign: String?
    /// "Fire" / "Earth" / "Air" / "Water".
    let element: String
    /// "Cardinal" / "Fixed" / "Mutable".
    let modality: String
    /// A short evocative line, e.g. "Fire-driven and immovable once you decide."
    let headline: String
}

enum CosmicSignatureMaker {
    private static let elementOrder = ["Fire", "Earth", "Air", "Water"]
    private static let modalityOrder = ["Cardinal", "Fixed", "Mutable"]

    static func make(from chart: NatalChart) -> CosmicSignature {
        let element = dominant(counts(in: chart, classify: element(of:)), order: elementOrder)
        let modality = dominant(counts(in: chart, classify: modality(of:)), order: modalityOrder)
        return CosmicSignature(
            sunSign: sign(of: "Sun", in: chart),
            moonSign: sign(of: "Moon", in: chart),
            risingSign: chart.houses.map { ChartGlyphs.sign(forLongitude: $0.ascendant) },
            element: element,
            modality: modality,
            headline: "\(elementWord(element)) and \(modalityWord(modality))."
        )
    }

    // MARK: - Weighted dominant

    /// Luminaries carry the most weight, personal planets next — so the "dominant"
    /// reflects the chart's core, not just a raw tally.
    private static func weight(for planet: String) -> Int {
        switch planet {
        case "Sun", "Moon": 3
        case "Mercury", "Venus", "Mars": 2
        default: 1
        }
    }

    private static func counts(in chart: NatalChart, classify: (String) -> String) -> [String: Int] {
        var counts: [String: Int] = [:]
        for planet in chart.planets {
            let sign = ChartGlyphs.sign(forLongitude: planet.longitude)
            counts[classify(sign), default: 0] += weight(for: planet.planet)
        }
        // A known ascendant counts like a luminary.
        if let ascendant = chart.houses?.ascendant {
            counts[classify(ChartGlyphs.sign(forLongitude: ascendant)), default: 0] += 3
        }
        return counts
    }

    /// Highest count wins; ties break by `order` (first wins) so it's stable.
    private static func dominant(_ counts: [String: Int], order: [String]) -> String {
        var best = order.first ?? "—"
        var bestCount = -1
        for key in order where (counts[key] ?? 0) > bestCount {
            bestCount = counts[key] ?? 0
            best = key
        }
        return best
    }

    // MARK: - Classification

    private static func sign(of planet: String, in chart: NatalChart) -> String? {
        chart.planets
            .first { $0.planet == planet }
            .map { ChartGlyphs.sign(forLongitude: $0.longitude) }
    }

    private static func element(of sign: String) -> String {
        switch sign {
        case "Aries", "Leo", "Sagittarius": "Fire"
        case "Taurus", "Virgo", "Capricorn": "Earth"
        case "Gemini", "Libra", "Aquarius": "Air"
        default: "Water"
        }
    }

    private static func modality(of sign: String) -> String {
        switch sign {
        case "Aries", "Cancer", "Libra", "Capricorn": "Cardinal"
        case "Taurus", "Leo", "Scorpio", "Aquarius": "Fixed"
        default: "Mutable"
        }
    }

    private static func elementWord(_ element: String) -> String {
        switch element {
        case "Fire": "Fire-driven"
        case "Earth": "Earth-grounded"
        case "Air": "Air-quick"
        default: "Water-deep"
        }
    }

    private static func modalityWord(_ modality: String) -> String {
        switch modality {
        case "Cardinal": "always the one to start"
        case "Fixed": "immovable once you decide"
        default: "endlessly adaptable"
        }
    }
}
