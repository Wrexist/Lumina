@testable import Lumina
import XCTest

/// Tests for the deterministic daily-reading composer — every reading is
/// grounded in the real transits, never invented.
final class DailyReadingTests: XCTestCase {
    func testEmptySkyReadsHonestly() {
        XCTAssertTrue(DailyReading.compose(from: []).contains("quiet sky"))
    }

    func testLeadTransitShapesTheReading() {
        let reading = DailyReading.compose(from: [transit("Mars", "Venus", .trine, applying: true)])
        XCTAssertTrue(reading.contains("Today, transiting Mars"))
        XCTAssertTrue(reading.contains("Venus"))
        XCTAssertTrue(reading.contains("easy current"))
        XCTAssertTrue(reading.contains("building"))
    }

    func testHardAspectReadsAsFriction() {
        let reading = DailyReading.compose(from: [transit("Saturn", "Sun", .square, applying: false)])
        XCTAssertTrue(reading.contains("friction"))
        XCTAssertTrue(reading.contains("easing"))
    }

    func testSecondTransitAppearsInBackground() {
        let reading = DailyReading.compose(from: [
            transit("Pluto", "Mercury", .trine, applying: false),
            transit("Venus", "Venus", .sextile, applying: true),
        ])
        XCTAssertTrue(reading.contains("In the background, transiting Venus"))
    }

    private func transit(_ transiting: String, _ natal: String, _ type: AspectType, applying: Bool) -> TransitReading {
        TransitReading(transiting: transiting, natal: natal, type: type, exactAngle: 0, orb: 1, applying: applying)
    }
}

/// The Today hero greeting. Time-dependent, so it takes an explicit date —
/// these pin the band boundaries and the no-name fallback.
final class DailyGreetingTests: XCTestCase {
    private func at(_ hour: Int) -> Date {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return utc.date(from: DateComponents(year: 2026, month: 6, day: 2, hour: hour)) ?? .distantPast
    }

    private func greeting(_ hour: Int, name: String = "Sam") -> String {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return DailyGreeting.text(for: at(hour), name: name, calendar: utc)
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
