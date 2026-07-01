@testable import Lumina
import XCTest

/// Tests for the (pure) chart-standout finder — stellium detection, unaspected
/// planet fallback, and staying quiet on an unremarkable chart.
final class ChartStandoutTests: XCTestCase {
    func testStelliumIsFound() {
        // Three planets in Aries (0–30°).
        let standout = ChartStandoutFinder.find(in: Self.chart(
            planets: [("Sun", 5), ("Moon", 10), ("Mercury", 20), ("Venus", 130), ("Mars", 200)],
            aspects: []
        ))
        XCTAssertEqual(standout?.headline, "Your Aries stellium")
    }

    func testUnaspectedPlanetIsFoundWhenNoStellium() {
        // No stellium; Sun and Moon aspect each other, Pluto stands alone.
        let standout = ChartStandoutFinder.find(in: Self.chart(
            planets: [("Sun", 5), ("Moon", 130), ("Pluto", 250)],
            aspects: [Self.aspect("Sun", "Moon")]
        ))
        XCTAssertEqual(standout?.headline, "Your Pluto stands alone")
    }

    func testNilWhenEveryPlanetIsAspectedAndNoStellium() {
        let standout = ChartStandoutFinder.find(in: Self.chart(
            planets: [("Sun", 5), ("Moon", 130)],
            aspects: [Self.aspect("Sun", "Moon")]
        ))
        XCTAssertNil(standout)
    }

    func testNilWhenNoAspectsAndNoStellium() {
        // With no aspects at all we must not call every planet "unaspected".
        let standout = ChartStandoutFinder.find(in: Self.chart(
            planets: [("Sun", 5), ("Moon", 130)],
            aspects: []
        ))
        XCTAssertNil(standout)
    }

    // MARK: - Helpers

    private static func aspect(_ planet1: String, _ planet2: String) -> NatalChart.Aspect {
        NatalChart.Aspect(planet1: planet1, planet2: planet2, type: .conjunction, exactAngle: 0, orb: 1)
    }

    private static func chart(planets: [(String, Double)], aspects: [NatalChart.Aspect]) -> NatalChart {
        NatalChart(
            calculatedAt: .now,
            houseSystem: .placidus,
            planets: planets.map {
                NatalChart.PlanetPosition(planet: $0.0, longitude: $0.1, latitude: 0, isRetrograde: false)
            },
            aspects: aspects,
            houses: nil
        )
    }
}
