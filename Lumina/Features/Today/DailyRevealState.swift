import Foundation

/// Gates the once-per-day "unveil" moment on the Today reading card: the
/// first visit of each calendar day starts veiled, and a tap reveals the
/// reading. Persists the last-revealed day as a "yyyy-MM-dd" string so
/// revisits within the same day show the reading directly.
///
/// Deliberately *not* a streak — nothing counts, nothing resets, nothing
/// guilts. Missing a day changes nothing except that the next visit gets
/// the small reveal moment again.
///
/// `UserDefaults` and `Calendar` are injectable so tests can isolate
/// persistence and pin the "day" boundary (see `DailyRevealTests`).
@MainActor
@Observable
final class DailyRevealState {
    /// Storage key for the last-revealed day string.
    static let defaultsKey = "luminaDailyRevealDay"

    private let defaults: UserDefaults
    private let calendar: Calendar

    /// The last revealed day as "yyyy-MM-dd" (`nil` before the first ever
    /// reveal). Observable, so the Today view swaps the veil for the
    /// reading in place when `markRevealed()` runs.
    private(set) var lastRevealedDay: String?

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
        lastRevealedDay = defaults.string(forKey: Self.defaultsKey)
    }

    /// Whether the reading has already been unveiled today.
    var isRevealedToday: Bool {
        isRevealed(on: .now)
    }

    /// Marks today's reading as unveiled and persists it.
    func markRevealed() {
        markRevealed(on: .now)
    }

    /// Whether the reading was unveiled on the calendar day containing
    /// `date`. Exposed for tests; app code goes through `isRevealedToday`.
    func isRevealed(on date: Date) -> Bool {
        lastRevealedDay == dayString(for: date)
    }

    /// Marks the calendar day containing `date` as revealed. Exposed for
    /// tests; app code goes through `markRevealed()`.
    func markRevealed(on date: Date) {
        let day = dayString(for: date)
        lastRevealedDay = day
        defaults.set(day, forKey: Self.defaultsKey)
    }

    /// "yyyy-MM-dd" from the injected calendar (whose time zone decides
    /// when "today" rolls over) — components, not `DateFormatter`, so no
    /// locale or era surprises.
    private func dayString(for date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
