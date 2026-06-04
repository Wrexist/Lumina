import Foundation

/// A grounded, deterministic interpretation of a single natal aspect — how two
/// of the user's planets relate. "Your Sun rubs against your Saturn — a
/// productive tension between your identity and your discipline." It composes
/// from real building blocks (each planet's theme × the aspect's dynamic), so
/// it's specific to the user's actual chart, never generic.
///
/// Like `PlacementInterpreter`, this is the deterministic grounding layer; a
/// richer narrated reading can layer on later without changing the contract.
enum AspectInterpreter {
    /// A one-sentence interpretation of `type` between `planet1` and `planet2`.
    static func interpretation(planet1: String, planet2: String, type: AspectType) -> String {
        let theme1 = planetTheme[planet1] ?? "this part of you"
        let theme2 = planetTheme[planet2] ?? "another part of you"
        return "Your \(planet1) \(verb(for: type)) your \(planet2) — \(synthesis(type, theme1, theme2))"
    }

    // MARK: - Building blocks

    /// The transitive relationship verb (singular: "<planet1> ___ your <planet2>").
    private static func verb(for type: AspectType) -> String {
        switch type {
        case .conjunction: "fuses with"
        case .trine: "flows easily with"
        case .sextile: "works well with"
        case .square: "rubs against"
        case .opposition: "stands opposite"
        }
    }

    /// The synthesis clause, with the right preposition per aspect quality.
    private static func synthesis(_ type: AspectType, _ theme1: String, _ theme2: String) -> String {
        switch type {
        case .conjunction: "an intense blend of \(theme1) and \(theme2)."
        case .trine: "an easy harmony between \(theme1) and \(theme2)."
        case .sextile: "a quiet support between \(theme1) and \(theme2)."
        case .square: "a productive tension between \(theme1) and \(theme2)."
        case .opposition: "a balancing act between \(theme1) and \(theme2)."
        }
    }

    /// What each planet stands for (fits "your ___").
    private static let planetTheme = [
        "Sun": "your identity",
        "Moon": "your feelings",
        "Mercury": "your mind",
        "Venus": "your loves",
        "Mars": "your drive",
        "Jupiter": "your growth",
        "Saturn": "your discipline",
        "Uranus": "your independence",
        "Neptune": "your dreams",
        "Pluto": "your power",
    ]
}
