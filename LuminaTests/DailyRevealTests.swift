@testable import Lumina
import XCTest

/// Tests for the once-per-day reveal gate on the Today reading card —
/// pure persistence + day-boundary logic, no views. Every test isolates
/// storage via its own `UserDefaults` suite and pins the day boundary via
/// an injected calendar.
@MainActor
final class DailyRevealTests: XCTestCase {
    /// 2001-09-09 01:46:40 UTC — a fixed instant so day math never depends
    /// on when the test suite runs.
    private let fixedDate = Date(timeIntervalSince1970: 1_000_000_000)

    func testFreshStateIsNotRevealed() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }

        let state = DailyRevealState(defaults: defaults, calendar: try utcCalendar())
        XCTAssertFalse(state.isRevealedToday)
        XCTAssertFalse(state.isRevealed(on: fixedDate))
        XCTAssertNil(state.lastRevealedDay)
    }

    func testMarkRevealedRoundTrip() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }

        let state = DailyRevealState(defaults: defaults, calendar: try utcCalendar())
        state.markRevealed(on: fixedDate)

        XCTAssertTrue(state.isRevealed(on: fixedDate))
        XCTAssertEqual(state.lastRevealedDay, "2001-09-09")
        XCTAssertEqual(defaults.string(forKey: DailyRevealState.defaultsKey), "2001-09-09")

        // A fresh instance over the same defaults sees the persisted day.
        let rehydrated = DailyRevealState(defaults: defaults, calendar: try utcCalendar())
        XCTAssertTrue(rehydrated.isRevealed(on: fixedDate))
    }

    func testNowConveniencesRoundTrip() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }

        let state = DailyRevealState(defaults: defaults, calendar: .current)
        XCTAssertFalse(state.isRevealedToday)
        state.markRevealed()
        XCTAssertTrue(state.isRevealedToday)
    }

    func testStaleStoredDayIsNotRevealed() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("2020-01-01", forKey: DailyRevealState.defaultsKey)

        let state = DailyRevealState(defaults: defaults, calendar: try utcCalendar())
        XCTAssertFalse(state.isRevealed(on: fixedDate), "yesterday's reveal must not carry over")
        XCTAssertFalse(state.isRevealedToday)

        // Revealing today replaces the stale day.
        state.markRevealed(on: fixedDate)
        XCTAssertTrue(state.isRevealed(on: fixedDate))
        XCTAssertEqual(defaults.string(forKey: DailyRevealState.defaultsKey), "2001-09-09")
    }

    func testDayBoundaryInInjectedCalendar() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }

        let state = DailyRevealState(defaults: defaults, calendar: try utcCalendar())
        state.markRevealed(on: fixedDate)

        let lateSameDay = fixedDate.addingTimeInterval(22 * 3_600) // 23:46 UTC same day
        let nextDay = fixedDate.addingTimeInterval(24 * 3_600) // 01:46 UTC next day
        XCTAssertTrue(state.isRevealed(on: lateSameDay))
        XCTAssertFalse(state.isRevealed(on: nextDay), "the veil returns after midnight")
    }

    func testCalendarTimeZoneDecidesTheDay() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }

        // 2001-09-09T23:00 UTC is already 2001-09-10 in Auckland (UTC+12).
        let nearUTCMidnight = fixedDate.addingTimeInterval(21 * 3_600 + 800)
        let utcState = DailyRevealState(defaults: defaults, calendar: try utcCalendar())
        utcState.markRevealed(on: nearUTCMidnight)
        XCTAssertEqual(utcState.lastRevealedDay, "2001-09-09")

        let aucklandState = DailyRevealState(
            defaults: defaults,
            calendar: try calendar(timeZoneIdentifier: "Pacific/Auckland")
        )
        XCTAssertFalse(
            aucklandState.isRevealed(on: nearUTCMidnight),
            "the same instant is a different calendar day in the injected zone"
        )
    }

    func testSuitesAreIsolated() throws {
        let (defaultsA, suiteA) = try makeDefaults()
        defer { defaultsA.removePersistentDomain(forName: suiteA) }
        let (defaultsB, suiteB) = try makeDefaults()
        defer { defaultsB.removePersistentDomain(forName: suiteB) }

        let stateA = DailyRevealState(defaults: defaultsA, calendar: try utcCalendar())
        stateA.markRevealed(on: fixedDate)

        let stateB = DailyRevealState(defaults: defaultsB, calendar: try utcCalendar())
        XCTAssertFalse(stateB.isRevealed(on: fixedDate), "reveals must not leak across defaults")
    }

    // MARK: - Helpers

    private func makeDefaults() throws -> (UserDefaults, String) {
        let suite = "lumina.tests.dailyreveal.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        return (defaults, suite)
    }

    private func utcCalendar() throws -> Calendar {
        try calendar(timeZoneIdentifier: "UTC")
    }

    private func calendar(timeZoneIdentifier: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: timeZoneIdentifier))
        return calendar
    }
}
