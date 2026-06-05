import Foundation

/// A grounded, deterministic reading of the rising sign (ascendant) — the
/// "first impression" framing every casual user recognises. Pure and
/// unit-testable, keyed to the user's actual ascendant longitude. The
/// ascendant isn't a planet, so it sits alongside `PlacementInterpreter`
/// rather than inside it, sharing the same never-invent-a-placement contract.
enum AscendantInterpreter {
    /// A 1–2 sentence reading of the ascendant at `longitude`. Always
    /// non-empty and specific to the rising sign.
    static func interpretation(longitude: Double) -> String {
        let sign = ChartGlyphs.sign(forLongitude: longitude)
        let impression = risingImpression[sign] ?? "distinctly, unmistakably yourself"
        return "Your rising sign is the first impression you make — the read people get "
            + "before you say a word. In \(sign), you tend to come across as \(impression)."
    }

    /// How each rising sign tends to read on first meeting (fits "you tend to
    /// come across as ___"). Distinct from a planet's inner drive — this is the
    /// outward door others arrive through.
    private static let risingImpression = [
        "Aries": "direct, energetic, and quick to engage",
        "Taurus": "calm, grounded, and reassuringly steady",
        "Gemini": "curious, talkative, and quick on your feet",
        "Cancer": "warm, gentle, and quietly protective",
        "Leo": "confident, radiant, and hard to miss",
        "Virgo": "composed, observant, and quietly capable",
        "Libra": "gracious, easygoing, and naturally diplomatic",
        "Scorpio": "intense, magnetic, and hard to read at first",
        "Sagittarius": "open, upbeat, and ready for what's next",
        "Capricorn": "reserved, capable, and quietly authoritative",
        "Aquarius": "original, friendly, and a little unconventional",
        "Pisces": "soft, dreamy, and easy to be around",
    ]
}
