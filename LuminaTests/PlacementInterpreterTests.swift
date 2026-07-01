@testable import Lumina
import XCTest

/// Tests for the deterministic, per-placement chart interpreter. Guards that
/// every reading is specific to the actual placement (not a generic blurb)
/// and composes cleanly across all planets, signs, houses, and retrograde.
final class PlacementInterpreterTests: XCTestCase {
    func testReadingIsSpecificToThePlacement() {
        // Venus at 75° = mid-Gemini, in the 9th house, direct.
        let text = PlacementInterpreter.interpretation(
            planet: "Venus", longitude: 75, house: 9, isRetrograde: false
        )
        XCTAssertTrue(text.contains("Venus"))
        XCTAssertTrue(text.contains("Gemini"))
        XCTAssertTrue(text.contains("how you love"))
        XCTAssertTrue(text.contains("curiosity, words, and variety"))
        XCTAssertTrue(text.contains("beliefs, travel, and the bigger picture"))
    }

    func testUnknownHouseOmitsTheHouseClause() {
        let text = PlacementInterpreter.interpretation(
            planet: "Mars", longitude: 15, house: nil, isRetrograde: false
        )
        XCTAssertFalse(text.contains("It plays out most in"))
        XCTAssertTrue(text.contains("Mars"))
        XCTAssertTrue(text.contains("Aries"))
    }

    func testRetrogradeAddsTheInwardNote() {
        let direct = PlacementInterpreter.interpretation(
            planet: "Mercury", longitude: 200, house: 3, isRetrograde: false
        )
        let retro = PlacementInterpreter.interpretation(
            planet: "Mercury", longitude: 200, house: 3, isRetrograde: true
        )
        XCTAssertFalse(direct.contains("Retrograde here"))
        XCTAssertTrue(retro.contains("Retrograde here"))
    }

    func testEveryPlanetComposesAndNamesItself() {
        for planet in ChartGlyphs.planetOrder {
            let text = PlacementInterpreter.interpretation(
                planet: planet, longitude: 75, house: nil, isRetrograde: false
            )
            XCTAssertFalse(text.isEmpty)
            XCTAssertTrue(text.contains(planet), "reading should name \(planet)")
            XCTAssertFalse(text.contains("this part of who you are"), "no fallback for \(planet)")
        }
    }

    func testEverySignAndHouseResolves() {
        for index in 0..<12 {
            let longitude = Double(index) * 30 + 15
            let sign = ChartGlyphs.signOrder[index]
            let text = PlacementInterpreter.interpretation(
                planet: "Sun", longitude: longitude, house: index + 1, isRetrograde: false
            )
            XCTAssertTrue(text.contains(sign), "reading should name \(sign)")
            XCTAssertTrue(text.contains("It plays out most in"), "house \(index + 1) should resolve")
            XCTAssertFalse(text.contains("unmistakable way"), "no sign fallback for \(sign)")
        }
    }

    func testDistinctPlacementsReadDifferently() {
        let venusGemini = PlacementInterpreter.interpretation(
            planet: "Venus", longitude: 75, house: 5, isRetrograde: false
        )
        let marsCapricorn = PlacementInterpreter.interpretation(
            planet: "Mars", longitude: 285, house: 10, isRetrograde: false
        )
        XCTAssertNotEqual(venusGemini, marsCapricorn)
    }
}
