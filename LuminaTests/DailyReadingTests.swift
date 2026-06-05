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
