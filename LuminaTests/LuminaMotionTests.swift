@testable import Lumina
import XCTest

/// The in-app "Reduce motion" override must combine with the OS setting, so the
/// Settings toggle isn't a dead control.
final class LuminaMotionTests: XCTestCase {
    func testReducedWhenEitherSystemOrOverrideIsOn() {
        XCTAssertFalse(LuminaMotion.isReduced(system: false, appOverride: false))
        XCTAssertTrue(LuminaMotion.isReduced(system: true, appOverride: false))
        XCTAssertTrue(LuminaMotion.isReduced(system: false, appOverride: true))
        XCTAssertTrue(LuminaMotion.isReduced(system: true, appOverride: true))
    }
}
