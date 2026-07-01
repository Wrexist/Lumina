@testable import Lumina
import XCTest

/// Tests for the (pure) grounding formatter — it must state only real facts, so
/// the LLM can't be handed anything to hallucinate from.
final class ChartFactsTests: XCTestCase {
    func testIncludesPlanetSignsAndRetrograde() {
        let summary = ChartFacts.summary(of: Self.chart(
            planets: [("Sun", 5, false), ("Saturn", 290, true)],
            houses: nil,
            aspects: []
        ))
        XCTAssertTrue(summary.contains("Sun in Aries"))
        XCTAssertTrue(summary.contains("Saturn in Capricorn (retrograde)"))
    }

    func testStatesWhenBirthTimeIsUnknown() {
        let summary = ChartFacts.summary(of: Self.chart(planets: [("Sun", 5, false)], houses: nil, aspects: []))
        XCTAssertTrue(summary.contains("Birth time unknown"))
        XCTAssertFalse(summary.contains("Ascendant"))
    }

    func testIncludesAscendantWhenHousesKnown() {
        let houses = NatalChart.HouseCusps(
            system: .placidus,
            ascendant: 192,
            midheaven: 106,
            cusps: Array(repeating: 0, count: 12)
        )
        let summary = ChartFacts.summary(of: Self.chart(planets: [("Sun", 5, false)], houses: houses, aspects: []))
        XCTAssertTrue(summary.contains("Ascendant (rising) in Libra"))
        XCTAssertTrue(summary.contains("Midheaven in"))
    }

    func testCapsAspectsAtEight() {
        let aspects = (0..<12).map { _ in
            NatalChart.Aspect(planet1: "Sun", planet2: "Moon", type: .trine, exactAngle: 120, orb: 1)
        }
        let summary = ChartFacts.summary(of: Self.chart(planets: [("Sun", 5, false)], houses: nil, aspects: aspects))
        let aspectLines = summary.split(separator: "\n").filter { $0.hasPrefix("- ") }
        XCTAssertEqual(aspectLines.count, 8)
    }

    // MARK: - Helpers

    private static func chart(
        planets: [(String, Double, Bool)],
        houses: NatalChart.HouseCusps?,
        aspects: [NatalChart.Aspect]
    ) -> NatalChart {
        NatalChart(
            calculatedAt: .now,
            houseSystem: .placidus,
            planets: planets.map {
                NatalChart.PlanetPosition(planet: $0.0, longitude: $0.1, latitude: 0, isRetrograde: $0.2)
            },
            aspects: aspects,
            houses: houses
        )
    }
}
