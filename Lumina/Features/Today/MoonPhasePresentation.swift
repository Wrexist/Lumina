import Foundation

/// Presentation helpers for the Moon card — pure mapping from the backend's
/// phase data to an SF Symbol and plain, honest copy. No invented mysticism;
/// just what the sky is actually doing tonight.
enum MoonPhasePresentation {
    /// The matching `moonphase.*` SF Symbol for a backend phase name.
    static func symbol(for phase: String) -> String {
        switch phase {
        case "New Moon": "moonphase.new.moon"
        case "Waxing Crescent": "moonphase.waxing.crescent"
        case "First Quarter": "moonphase.first.quarter"
        case "Waxing Gibbous": "moonphase.waxing.gibbous"
        case "Full Moon": "moonphase.full.moon"
        case "Waning Gibbous": "moonphase.waning.gibbous"
        case "Last Quarter": "moonphase.last.quarter"
        case "Waning Crescent": "moonphase.waning.crescent"
        default: "moon"
        }
    }

    /// "73% illuminated".
    static func illuminationText(_ fraction: Double) -> String {
        let percent = Int((fraction * 100).rounded())
        return "\(percent)% illuminated"
    }

    /// The nearer of the next new/full moon, phrased relative to now:
    /// "Full moon in 6 days", "New moon tomorrow".
    static func nextEvent(nextNew: Date, nextFull: Date, now: Date = .now) -> String {
        let newDays = days(from: now, to: nextNew)
        let fullDays = days(from: now, to: nextFull)
        if fullDays <= newDays {
            return "Full moon \(relative(fullDays))"
        }
        return "New moon \(relative(newDays))"
    }

    /// Calendar-day difference, so "tomorrow" is the next calendar day —
    /// 11 pm to 1 am is tomorrow, not a rounded-down "today".
    private static func days(from: Date, to: Date) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: from),
            to: calendar.startOfDay(for: to)
        ).day ?? 0
    }

    private static func relative(_ days: Int) -> String {
        switch days {
        case ...0: "today"
        case 1: "tomorrow"
        default: "in \(days) days"
        }
    }
}
