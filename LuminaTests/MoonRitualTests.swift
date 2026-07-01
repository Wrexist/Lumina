@testable import Lumina
import XCTest

/// Tests for the (pure) lunar-ritual prompt — new-moon intentions near new,
/// full-moon release near full, nothing in between.
final class MoonRitualTests: XCTestCase {
    func testNewMoonWindowSuggestsAnIntention() throws {
        XCTAssertTrue(try XCTUnwrap(MoonRitual.prompt(forAngle: 0)).contains("intention"))
        XCTAssertTrue(try XCTUnwrap(MoonRitual.prompt(forAngle: 44)).contains("intention"))
        XCTAssertEqual(MoonRitual.callToAction(forAngle: 10), "Set an intention")
    }

    func testFullMoonWindowSuggestsRelease() throws {
        XCTAssertTrue(try XCTUnwrap(MoonRitual.prompt(forAngle: 180)).contains("release"))
        XCTAssertEqual(MoonRitual.callToAction(forAngle: 180), "Reflect and release")
    }

    func testQuartersAndWaningHaveNoRitual() {
        XCTAssertNil(MoonRitual.prompt(forAngle: 90))
        XCTAssertNil(MoonRitual.prompt(forAngle: 270))
        XCTAssertNil(MoonRitual.prompt(forAngle: 45))
        XCTAssertNil(MoonRitual.prompt(forAngle: 200))
    }

    func testAngleIsNormalized() throws {
        XCTAssertTrue(try XCTUnwrap(MoonRitual.prompt(forAngle: 360)).contains("intention"))
        XCTAssertNil(MoonRitual.prompt(forAngle: -10))
    }
}
