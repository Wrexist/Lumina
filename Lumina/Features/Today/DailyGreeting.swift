import Foundation

/// The Today hero's greeting line.
///
/// Pure and testable rather than inline in the view, because it depends on the
/// wall clock — the one input a screenshot or a unit test has to be able to
/// pin. `TodayHubView` passes `.now`; tests pass a fixed hour.
enum DailyGreeting {
    /// Time-of-day bands. Deliberately coarse: the point is that the app
    /// sounds like it knows roughly when you opened it, not that it splits
    /// hairs at 11:59.
    static func text(for date: Date, name: String, calendar: Calendar = .current) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let salutation = salutation(for: calendar.component(.hour, from: date))
        // Falls back to the impersonal line when onboarding collected no name
        // or the account was erased — never "Good evening, ".
        return trimmed.isEmpty ? salutation : "\(salutation), \(trimmed)"
    }

    private static func salutation(for hour: Int) -> String {
        switch hour {
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        case 18..<22: "Good evening"
        // Late night gets its own line rather than being rounded into
        // "evening" — someone opening this at 2am is having a different
        // moment, and the app's whole voice is about noticing that.
        default: "Still up"
        }
    }
}
