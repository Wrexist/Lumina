@testable import Lumina
import XCTest

/// Tests for the deterministic natal-aspect interpreter. Guards that each
/// reading names both planets, reads distinctly per aspect type, and never
/// falls back to a placeholder for a real planet.
final class AspectInterpreterTests: XCTestCase {
    func testReadsExactlyAsComposed() {
        let text = AspectInterpreter.interpretation(planet1: "Sun", planet2: "Saturn", type: .square)
        XCTAssertEqual(
            text,
            "Your Sun rubs against your Saturn — a productive tension between your identity and your discipline."
        )
    }

    func testEachAspectTypeReadsDistinctly() {
        let types: [AspectType] = [.conjunction, .trine, .sextile, .square, .opposition]
        let readings = types.map {
            AspectInterpreter.interpretation(planet1: "Venus", planet2: "Mars", type: $0)
        }
        XCTAssertEqual(Set(readings).count, types.count, "each aspect type should read differently")
    }

    func testEveryPlanetThemeResolves() {
        for planet in ChartGlyphs.planetOrder {
            let text = AspectInterpreter.interpretation(planet1: planet, planet2: "Moon", type: .trine)
            XCTAssertTrue(text.contains(planet))
            XCTAssertFalse(text.contains("this part of you"), "no theme fallback for \(planet)")
            XCTAssertFalse(text.contains("another part of you"))
        }
    }

    func testHarmoniousAndChallengingDiffer() {
        let trine = AspectInterpreter.interpretation(planet1: "Sun", planet2: "Moon", type: .trine)
        let square = AspectInterpreter.interpretation(planet1: "Sun", planet2: "Moon", type: .square)
        XCTAssertNotEqual(trine, square)
        XCTAssertTrue(trine.contains("easy harmony"))
        XCTAssertTrue(square.contains("productive tension"))
    }
}
