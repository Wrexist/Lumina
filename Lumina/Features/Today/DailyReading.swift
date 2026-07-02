import Foundation

/// A grounded daily reading composed from the day's real transits — the Today
/// tab's core content. Deterministic (no language model), so nothing is
/// invented: it names the actual contacts and what they invite, framed for
/// today. The narrated *audio* version (ElevenLabs) layers on later; the words
/// are real now.
enum DailyReading {
    /// A 1–3 sentence *standalone* reading from `transits` (tightest first,
    /// as the backend returns them) — used where the reading travels alone,
    /// like the share image. An empty sky gets an honest "quiet day" reading.
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

    /// The on-screen reading body that sits under the reading card's headline.
    /// The headline (`TransitPhrasing.sentence`) already names the lead
    /// contact and the collapsed "Details" rows carry the rest, so this opens
    /// straight with the lead's invitation — no transit is phrased twice on
    /// the screen.
    static func bodyText(from transits: [TransitReading]) -> String {
        guard let lead = transits.first else {
            return "No major transits are touching your chart right now. "
                + "A good day to set your own pace."
        }
        let domain = planetDomain[lead.natal] ?? "your chart"
        return invitationSentence(lead.type, domain) + " " + closing(applying: lead.applying)
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

    /// `invitation(_:_:)` as a standalone sentence, for `bodyText(from:)`.
    private static func invitationSentence(_ type: AspectType, _ domain: String) -> String {
        switch type {
        case .trine, .sextile: "An easy current to lean into around \(domain)."
        case .conjunction: "An intense focus on \(domain)."
        case .square, .opposition: "Some friction around \(domain), so move with care."
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
