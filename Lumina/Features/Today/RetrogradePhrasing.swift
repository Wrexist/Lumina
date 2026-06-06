import Foundation

/// Plain, calm copy for retrograde motion — the most-asked astrology question
/// ("is Mercury retrograde?"), answered from the real ephemeris and framed
/// without doom. Pure and unit-testable.
enum RetrogradePhrasing {
    /// "Mercury and Saturn are retrograde right now." (or the singular / none
    /// variants). Lists the bodies currently in apparent backward motion.
    static func summary(for result: RetrogradesResult) -> String {
        let names = result.planets.filter(\.isRetrograde).map(\.planet)
        switch names.count {
        case 0:
            return "No planets are retrograde right now — a clear, direct sky."
        case 1:
            return "\(names[0]) is retrograde right now."
        default:
            return "\(listPhrase(names)) are retrograde right now."
        }
    }

    /// "Mercury turns direct on Apr 7." Nil when the body has no upcoming station.
    static func stationLine(for state: RetrogradeState, formatter: DateFormatter) -> String? {
        guard let stationAt = state.nextStationAt, let direction = state.nextStationDirection else {
            return nil
        }
        let verb = direction == .direct ? "turns direct" : "stations retrograde"
        return "\(state.planet) \(verb) \(formatter.string(from: stationAt))."
    }

    /// "A, B and C".
    private static func listPhrase(_ names: [String]) -> String {
        guard let last = names.last else { return "" }
        guard names.count > 1 else { return last }
        return "\(names.dropLast().joined(separator: ", ")) and \(last)"
    }
}
