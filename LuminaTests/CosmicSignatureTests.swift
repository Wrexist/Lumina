@testable import Lumina
import XCTest

/// Tests for the (pure) cosmic-signature engine — dominant element/modality
/// (weighted toward the luminaries + rising), Big-3, and the headline.
final class CosmicSignatureTests: XCTestCase {
    func testFireCardinalChartIsReadCorrectly() {
        // Sun Aries, Moon Leo, Mercury Sagittarius, Aries rising → Fire dominant;
        // Cardinal wins on Sun (3) + Ascendant (3) over Moon's Fixed (3).
        let signature = CosmicSignatureMaker.make(from: Self.chart(
            planets: [("Sun", 15), ("Moon", 135), ("Mercury", 255)],
            ascendant: 15
        ))
        XCTAssertEqual(signature.sunSign, "Aries")
        XCTAssertEqual(signature.moonSign, "Leo")
        XCTAssertEqual(signature.risingSign, "Aries")
        XCTAssertEqual(signature.element, "Fire")
        XCTAssertEqual(signature.modality, "Cardinal")
        XCTAssertEqual(signature.headline, "Fire-driven and always the one to start.")
    }

    func testLuminariesOutweighOuterPlanets() {
        // Two luminaries in Water (weight 3 each = 6) beat three outer planets in
        // Air (weight 1 each = 3).
        let signature = CosmicSignatureMaker.make(from: Self.chart(
            planets: [
                ("Sun", 105),   // Cancer (Water)
                ("Moon", 345),  // Pisces (Water)
                ("Uranus", 75), // Gemini (Air)
                ("Neptune", 195), // Libra (Air)
                ("Pluto", 315), // Aquarius (Air)
            ],
            ascendant: nil
        ))
        XCTAssertEqual(signature.element, "Water")
        XCTAssertNil(signature.risingSign)
    }

    func testHeadlineComposesElementAndModalityWords() {
        // Taurus stellium → Earth + Fixed.
        let signature = CosmicSignatureMaker.make(from: Self.chart(
            planets: [("Sun", 45), ("Moon", 50), ("Venus", 40)],
            ascendant: 45
        ))
        XCTAssertEqual(signature.element, "Earth")
        XCTAssertEqual(signature.modality, "Fixed")
        XCTAssertEqual(signature.headline, "Earth-grounded and immovable once you decide.")
    }

    // MARK: - Helpers

    private static func chart(planets: [(String, Double)], ascendant: Double?) -> NatalChart {
        let positions = planets.map {
            NatalChart.PlanetPosition(planet: $0.0, longitude: $0.1, latitude: 0, isRetrograde: false)
        }
        let houses = ascendant.map {
            NatalChart.HouseCusps(
                system: .placidus,
                ascendant: $0,
                midheaven: 0,
                cusps: Array(repeating: 0, count: 12)
            )
        }
        return NatalChart(
            calculatedAt: .now,
            houseSystem: .placidus,
            planets: positions,
            aspects: [],
            houses: houses
        )
    }
}
