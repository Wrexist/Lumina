import Foundation

/// Turns a composite (midpoint) chart into plain, grounded copy for the People
/// tab — the relationship "as its own chart". No invented imagery: just the
/// composite's core sign placements and the tightest real aspect within it.
/// Shares the aspect vocabulary with `TransitPhrasing`.
enum CompositePhrasing {
    /// "As a pair, your relationship carries its Sun in Libra and its Moon in
    /// Gemini." Nil when the composite has no Sun (i.e. an empty result).
    static func headline(for composite: CompositeResult) -> String? {
        guard let sun = sign(of: "Sun", in: composite) else { return nil }
        var line = "As a pair, your relationship carries its Sun in \(sun)"
        if let moon = sign(of: "Moon", in: composite) {
            line += " and its Moon in \(moon)"
        }
        return line + "."
    }

    /// The relationship's core placements as label/sign rows for a compact band.
    static func coreSigns(for composite: CompositeResult) -> [CoreSign] {
        ["Sun", "Moon", "Venus"].compactMap { name in
            sign(of: name, in: composite).map { CoreSign(planet: name, sign: $0) }
        }
    }

    /// "Sun conjunct Venus" — the tightest composite aspect, or nil when none.
    static func tightestAspect(for composite: CompositeResult) -> String? {
        guard let aspect = composite.aspects.first else { return nil }
        return "\(aspect.planet1) \(TransitPhrasing.aspectWord(aspect.type)) \(aspect.planet2)"
    }

    private static func sign(of planet: String, in composite: CompositeResult) -> String? {
        composite.planets
            .first(where: { $0.planet == planet })
            .map { ChartGlyphs.sign(forLongitude: $0.longitude) }
    }

    /// One core placement of the composite chart, for the compact sign band.
    struct CoreSign: Identifiable, Hashable {
        let planet: String
        let sign: String
        var id: String { planet }
    }
}
