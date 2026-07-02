import Foundation

/// Plain copy for planetary returns — the Saturn/Jupiter return as a calm
/// life-stage checkpoint, not a prophecy. Pure and unit-testable.
enum ReturnPhrasing {
    /// "Your second Saturn return arrives April 2049."
    static func line(for event: ReturnEvent, formatter: DateFormatter) -> String {
        "Your \(ordinal(event.returnNumber)) \(event.planet) return arrives \(formatter.string(from: event.exactAt))."
    }

    /// The returns landing within `days` of `reference`, soonest first — used to
    /// surface a return only when it's actually near.
    static func imminent(_ events: [ReturnEvent], within days: Int, from reference: Date) -> [ReturnEvent] {
        let cutoff = reference.addingTimeInterval(Double(days) * 86_400)
        return events
            .filter { $0.exactAt >= reference && $0.exactAt <= cutoff }
            .sorted { $0.exactAt < $1.exactAt }
    }

    private static func ordinal(_ number: Int) -> String {
        switch number {
        case 1: "first"
        case 2: "second"
        case 3: "third"
        default: spelledOrdinal(number)
        }
    }

    /// "4th", "21st" — `NumberFormatter` gets the suffix right where a naive
    /// "\(number)th" produced "21th". A fresh formatter per call keeps this
    /// pure and avoids sharing non-Sendable state across isolation domains
    /// (returns past the third are rare enough that the cost is nil).
    private static func spelledOrdinal(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}
