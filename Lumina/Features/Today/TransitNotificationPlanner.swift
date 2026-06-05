import Foundation

/// Turns an upcoming-transit `ForecastResult` into a small, kind set of local
/// notifications. Deliberately anti-anxiety: it delivers at a humane hour on
/// the transit's day (never the exact 3 AM minute), skips the fast-moving Moon,
/// caps the count, and never frames a transit as doom. Pure and unit-testable.
enum TransitNotificationPlanner {
    /// Delivered late-morning on the transit's day — "today", not "right now".
    private static let deliveryHour = 9
    /// Cap so we never spam — a handful of the soonest, most meaningful hits.
    static let defaultLimit = 5

    static func plan(
        from forecast: ForecastResult,
        now: Date = .now,
        limit: Int = defaultLimit,
        calendar: Calendar = .current
    ) -> [PlannedTransitNotification] {
        let planned = forecast.events
            .filter { $0.transiting != "Moon" }
            .compactMap { event -> PlannedTransitNotification? in
                let components = deliveryComponents(for: event.exactAt, calendar: calendar)
                // Drop anything whose humane delivery time has already passed
                // (e.g. a transit later today, after this morning's slot).
                guard let fireDate = calendar.date(from: components), fireDate > now else { return nil }
                return PlannedTransitNotification(
                    id: event.id,
                    title: ForecastPhrasing.line(for: event),
                    body: body(for: event.type),
                    fireDateComponents: components
                )
            }
        return Array(planned.prefix(limit))
    }

    // MARK: - Building blocks

    private static func deliveryComponents(for date: Date, calendar: Calendar) -> DateComponents {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = deliveryHour
        components.minute = 0
        return components
    }

    /// A gentle, honest one-liner keyed only to the aspect's tone — the title
    /// already carries the real specifics, so the body never fabricates.
    private static func body(for type: AspectType) -> String {
        switch type {
        case .trine, .sextile: "An easeful window for this part of your chart — worth leaning into."
        case .square, .opposition: "This one can feel like friction. Be gentle with yourself today."
        case .conjunction: "A fresh charge here today — notice what it stirs up."
        }
    }
}
