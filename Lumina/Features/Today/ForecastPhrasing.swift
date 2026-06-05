import Foundation

/// Turns a `ForecastEvent` into a plain line: "Saturn square your Sun".
/// Shares the aspect vocabulary with `TransitPhrasing`.
enum ForecastPhrasing {
    static func line(for event: ForecastEvent) -> String {
        "\(event.transiting) \(TransitPhrasing.aspectWord(event.type)) your \(event.natal)"
    }
}
