import Foundation

/// Maps the day's strongest transit to a grounded, reflective journal prompt —
/// so the Reflect prompt responds to the *real* sky (the natal planet being
/// touched, and whether the contact flows or grinds) instead of a generic
/// daily question. Pure and unit-testable. Output stays jargon-free and always
/// opens a question, never a directive — matching `JournalPromptGenerator`.
enum TransitPrompt {
    /// The strongest transit to key the day on: the tightest *applying* contact
    /// (input is tightest-first, as the backend returns it), or the tightest
    /// overall if none are applying. Nil when there are no transits.
    static func strongest(in transits: [TransitReading]) -> TransitReading? {
        transits.first(where: { $0.applying }) ?? transits.first
    }

    /// A reflective question keyed to one transit. The natal planet sets the
    /// life area; the aspect's tone sets whether it reads as ease or friction.
    static func prompt(for transit: TransitReading) -> String {
        let area = natalArea[transit.natal] ?? "something in you"
        switch tone(of: transit.type) {
        case .flowing:
            return "There's some ease around \(area) today — where could you lean into it?"
        case .frictional:
            return "Something's pressing on \(area) today — what's it asking you to look at?"
        case .charged:
            return "There's a fresh charge around \(area) today — what wants your attention there?"
        }
    }

    /// Stable grouping key for a transit-tied entry: the same dominant transit
    /// reuses the same key. Mirrors the `transit:<…>` form anticipated by
    /// `JournalPromptGenerator.transitKey`.
    static func key(for transit: TransitReading) -> String {
        "transit:\(transit.transiting)-\(transit.type.rawValue)-\(transit.natal)"
    }

    // MARK: - Building blocks

    private enum Tone {
        case flowing
        case frictional
        case charged
    }

    private static func tone(of type: AspectType) -> Tone {
        switch type {
        case .trine, .sextile: .flowing
        case .square, .opposition: .frictional
        case .conjunction: .charged
        }
    }

    /// The life area each natal planet governs, phrased to fit "around ___" and
    /// "pressing on ___".
    private static let natalArea = [
        "Sun": "your sense of self",
        "Moon": "your emotional world",
        "Mercury": "your thoughts and conversations",
        "Venus": "your relationships and values",
        "Mars": "your drive and desire",
        "Jupiter": "your growth and outlook",
        "Saturn": "your commitments and structure",
        "Uranus": "your freedom and what you'd change",
        "Neptune": "your dreams and what feels unclear",
        "Pluto": "your deeper changes",
    ]
}
