import Foundation

/// A grounded, deterministic interpretation of a single natal placement —
/// "Your Venus shapes how you love…; in Gemini, that comes through curiosity,
/// words, and variety." It composes from real astrological building blocks
/// (the planet's drive × the sign's manner × the house's arena × retrograde),
/// keyed to the user's *actual* placement — so it's specific to their chart,
/// never a generic horoscope shared across millions (see
/// `docs/COMPETITIVE-ANALYSIS.md`, gap G2).
///
/// This is the deterministic grounding layer. A richer, narrated reading
/// (RAG corpus + language model, server-side) layers on top later without
/// changing this contract — and can only ever *enrich* facts that are already
/// true here, never invent placements.
enum PlacementInterpreter {
    /// A 1–3 sentence interpretation of `planet` at `longitude`, optionally in
    /// `house`, flagged `isRetrograde`. Always non-empty and placement-specific.
    static func interpretation(
        planet: String,
        longitude: Double,
        house: Int?,
        isRetrograde: Bool
    ) -> String {
        let sign = ChartGlyphs.sign(forLongitude: longitude)
        let drive = planetDrive[planet] ?? "this part of who you are"
        let manner = signManner[sign] ?? "its own unmistakable way"

        var text = "Your \(planet) shapes \(drive); in \(sign), that comes through \(manner)."
        if let house, let arena = houseArena[house] {
            text += " It plays out most in \(arena)."
        }
        if isRetrograde {
            text += " Retrograde here, that energy works inward — more revisited and refined than broadcast."
        }
        return text
    }

    // MARK: - Building blocks

    /// What each planet governs (fits "Your <planet> shapes ___").
    private static let planetDrive = [
        "Sun": "your core identity and what lights you up",
        "Moon": "your emotional needs and what makes you feel safe",
        "Mercury": "how you think, learn, and communicate",
        "Venus": "how you love and what you find beautiful",
        "Mars": "how you assert yourself and chase what you want",
        "Jupiter": "where you seek growth, luck, and meaning",
        "Saturn": "where you meet discipline, limits, and lasting structure",
        "Uranus": "where you break from convention and reach for freedom",
        "Neptune": "where you dream, dissolve, and seek the transcendent",
        "Pluto": "where you transform, and where your power runs deepest",
    ]

    /// How each sign expresses (fits "that comes through ___").
    private static let signManner = [
        "Aries": "direct action, courage, and a need to go first",
        "Taurus": "steadiness, the senses, and what lasts",
        "Gemini": "curiosity, words, and variety",
        "Cancer": "feeling, care, and a long memory",
        "Leo": "warmth, heart, and a flair for the dramatic",
        "Virgo": "precision, craft, and the urge to improve",
        "Libra": "balance, beauty, and relationship",
        "Scorpio": "depth, intensity, and all-or-nothing focus",
        "Sagittarius": "expansion, meaning, and a reach for the horizon",
        "Capricorn": "ambition, patience, and the long game",
        "Aquarius": "invention, independence, and an eye on the future",
        "Pisces": "imagination, empathy, and a soft, fluid edge",
    ]

    /// The life arena each house governs (fits "It plays out most in ___").
    private static let houseArena = [
        1: "how you show up and the self you lead with",
        2: "your resources, values, and sense of self-worth",
        3: "your daily mind, words, and immediate surroundings",
        4: "your home, roots, and inner foundation",
        5: "creativity, play, romance, and self-expression",
        6: "work, routines, health, and craft",
        7: "partnership and one-to-one relationships",
        8: "intimacy, shared resources, and deep change",
        9: "beliefs, travel, and the bigger picture",
        10: "career, reputation, and your public role",
        11: "friendship, community, and your hopes for the future",
        12: "your inner life, the unconscious, and what stays private",
    ]
}
