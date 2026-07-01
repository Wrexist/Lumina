@testable import Lumina
import XCTest

/// Tests for the deterministic ascendant (rising-sign) interpreter. Like the
/// placement and aspect interpreters, it must be specific to the sign and
/// never empty.
final class AscendantInterpreterTests: XCTestCase {
    func testInterpretationNamesTheRisingSign() {
        // 15° → Aries.
        let text = AscendantInterpreter.interpretation(longitude: 15)
        XCTAssertTrue(text.contains("Aries"))
        XCTAssertTrue(text.contains("first impression"))
    }

    func testInterpretationVariesBySign() {
        let aries = AscendantInterpreter.interpretation(longitude: 15)
        let libra = AscendantInterpreter.interpretation(longitude: 195)
        XCTAssertNotEqual(aries, libra)
        XCTAssertTrue(libra.contains("Libra"))
    }

    func testInterpretationIsNonEmptyForEverySign() {
        for degrees in stride(from: 0, to: 360, by: 30) {
            let text = AscendantInterpreter.interpretation(longitude: Double(degrees))
            XCTAssertFalse(text.isEmpty)
            // Each 30° step lands in a new sign; the sign name should appear.
            let sign = ChartGlyphs.sign(forLongitude: Double(degrees))
            XCTAssertTrue(text.contains(sign), "missing \(sign) at \(degrees)°")
        }
    }
}
