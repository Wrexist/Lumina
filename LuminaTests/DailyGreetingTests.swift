@testable import Lumina
import XCTest

/// The Today hero greeting. Time-dependent, so it takes an explicit date —
/// these pin the band boundaries and the no-name fallback.
final class DailyGreetingTests: XCTestCase {
    /// Fixed UTC so the bands don't shift with the runner's locale.
    private static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    private func greeting(_ hour: Int, name: String = "Sam") -> String {
        let components = DateComponents(year: 2026, month: 6, day: 2, hour: hour)
        let date = Self.utc.date(from: components) ?? .distantPast
        return DailyGreeting.text(for: date, name: name, calendar: Self.utc)
    }

    func testSalutationTracksTheClock() {
        XCTAssertEqual(greeting(8), "Good morning, Sam")
        XCTAssertEqual(greeting(14), "Good afternoon, Sam")
        XCTAssertEqual(greeting(20), "Good evening, Sam")
        XCTAssertEqual(greeting(2), "Still up, Sam")
    }

    func testBandBoundaries() {
        XCTAssertEqual(greeting(4), "Still up, Sam")
        XCTAssertEqual(greeting(5), "Good morning, Sam")
        XCTAssertEqual(greeting(11), "Good morning, Sam")
        XCTAssertEqual(greeting(12), "Good afternoon, Sam")
        XCTAssertEqual(greeting(17), "Good afternoon, Sam")
        XCTAssertEqual(greeting(18), "Good evening, Sam")
        XCTAssertEqual(greeting(21), "Good evening, Sam")
        XCTAssertEqual(greeting(22), "Still up, Sam")
    }

    /// No name given, or the account was erased — never "Good evening, ".
    func testFallsBackWhenNoNameIsKnown() {
        XCTAssertEqual(greeting(20, name: ""), "Good evening")
        XCTAssertEqual(greeting(20, name: "   "), "Good evening")
        XCTAssertFalse(greeting(20, name: "").hasSuffix(","))
    }

    func testTrimsWhitespaceAroundTheName() {
        XCTAssertEqual(greeting(8, name: "  Sam  "), "Good morning, Sam")
    }
}
