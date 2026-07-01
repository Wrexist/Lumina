import Foundation

/// A grounded daily reading composed from the day's real transits — the Today
/// tab's core content. Deterministic (no language model), so nothing is
/// invented: it names the actual contacts and what they invite, framed for
/// today. The narrated *audio* version (ElevenLabs) layers on later; the words
/// are real now.
enum DailyReading {
    /// A 1–3 sentence reading from `transits` (tightest first, as the backend
    /// returns them). An empty sky gets an honest "quiet day" reading.
    static func compose(from transits: [TransitReading]) -> String {
        guard let lead = transits.first else {
            return "A quiet sky today — no major transits are touching your chart. "
                + "A good day to set your own pace."
        }
        var text = leadSentence(lead)
        if transits.count > 1 {
            text += " " + secondarySentence(transits[1])
        }
        text += " " + closing(applying: lead.applying)
        return text
    }

    private static func leadSentence(_ transit: TransitReading) -> String {
        let domain = planetDomain[transit.natal] ?? "your chart"
        return "Today, transiting \(transit.transiting) \(verb(transit.type)) your \(transit.natal) — "
            + invitation(transit.type, domain)
    }

    private static func secondarySentence(_ transit: TransitReading) -> String {
        "In the background, transiting \(transit.transiting) \(verb(transit.type)) your \(transit.natal)."
    }

    private static func closing(applying: Bool) -> String {
        applying
            ? "It's still building, so expect it to sharpen over the next day or two."
            : "It's easing now — you're past the strongest of it."
    }

    private static func verb(_ type: AspectType) -> String {
        switch type {
        case .conjunction: "meets"
        case .trine, .sextile: "flows with"
        case .square, .opposition: "presses on"
        }
    }

    private static func invitation(_ type: AspectType, _ domain: String) -> String {
        switch type {
        case .trine, .sextile: "an easy current to lean into around \(domain)."
        case .conjunction: "an intense focus on \(domain)."
        case .square, .opposition: "some friction around \(domain), so move with care."
        }
    }

    private static let planetDomain = [
        "Sun": "your sense of self",
        "Moon": "your feelings",
        "Mercury": "your mind",
        "Venus": "your loves",
        "Mars": "your drive",
        "Jupiter": "your growth",
        "Saturn": "your structures",
        "Uranus": "your independence",
        "Neptune": "your dreams",
        "Pluto": "your depths",
    ]
}
