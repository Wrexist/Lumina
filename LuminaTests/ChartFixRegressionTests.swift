@testable import Lumina
import SwiftUI
import XCTest

/// Regression tests for the 2026-07 chart fixes. Each guards a specific bug:
/// the mandala's zero-offset (every gate was shifted by one), channel-based
/// center definition (a hanging gate must not define a center), duplicate
/// planet names in a malformed payload, sample-aspect ordering, and
/// `ChartOracle` determinism.
final class ChartFixRegressionTests: XCTestCase {
    // MARK: - Mandala anchor (Gate 25 ENDS, not begins, at 3°52'30" Aries)

    func testZeroAriesFallsInGateTwentyFive() {
        // Canonical anchor: Gate 25 spans 28°15'00" Pisces – 3°52'30" Aries,
        // so 0° Aries sits inside it. The old +3.875 offset put it in Gate 36.
        XCTAssertEqual(HumanDesignMandala.gate(forLongitude: 0.0), 25)
    }

    func testGateTwentyFiveEdges() {
        // Leading edge at 28°15'00" Pisces = 358.25°; just before is Gate 36.
        XCTAssertEqual(HumanDesignMandala.gate(forLongitude: 358.25), 25)
        XCTAssertEqual(HumanDesignMandala.gate(forLongitude: 358.24), 36)
        // Trailing edge at 3°52'30" Aries = 3.875°; from there Gate 17 begins.
        XCTAssertEqual(HumanDesignMandala.gate(forLongitude: 3.874), 25)
        XCTAssertEqual(HumanDesignMandala.gate(forLongitude: 3.876), 17)
    }

    func testTwoDegreesAquariusBeginsGateFortyOne() {
        // Second canonical anchor: Gate 41 (the Rave New Year gate) begins
        // at exactly 2°00' Aquarius = 302.0°; Gate 60 sits just before it.
        XCTAssertEqual(HumanDesignMandala.gate(forLongitude: 302.0), 41)
        XCTAssertEqual(HumanDesignMandala.gate(forLongitude: 301.99), 60)
    }

    func testLineBoundariesAroundZeroAries() {
        // Gate 25 line 1 starts at 358.25°; line 2 spans 359.1875°–0.125°,
        // so 0° Aries is Gate 25.2 and line 3 starts at 0°07'30" Aries.
        XCTAssertEqual(HumanDesignMandala.line(forLongitude: 358.3), 1)
        XCTAssertEqual(HumanDesignMandala.line(forLongitude: 0.0), 2)
        XCTAssertEqual(HumanDesignMandala.line(forLongitude: 0.13), 3)
    }

    // MARK: - Center definition requires a complete channel

    func testHangingGateDoesNotDefineACenter() {
        // A single activation (Gate 1, G Center) is a hanging gate — its
        // channel partner (Gate 8) is missing, so no center is defined.
        let chart = makeChart(planets: [planet("Sun", at: 224.0)])
        let activation = HumanDesignActivation.compute(from: chart)
        XCTAssertTrue(activation.activatedGates.contains(1))
        XCTAssertTrue(activation.definedCenters.isEmpty)
    }

    func testCompleteChannelDefinesBothCenters() {
        // Gates 1 (G) + 8 (Throat) complete the 1-8 channel "Inspiration".
        //
        // The Earth rides exactly opposite the Sun, so it lands on gate 2 —
        // activated, but its partner (gate 14) isn't, so it hangs and defines
        // nothing. That is precisely the rule this test exists to pin, now
        // with a live example of it in the same fixture.
        let chart = makeChart(planets: [
            planet("Sun", at: 224.0), // Gate 1 — Earth opposite at 44° is gate 2
            planet("Moon", at: 55.0), // Gate 8
        ])
        let activation = HumanDesignActivation.compute(from: chart)
        XCTAssertEqual(activation.activatedGates, [1, 2, 8])
        XCTAssertEqual(activation.definedCenters, [.g, .throat])
        XCTAssertEqual(HumanDesignChannels.defined(in: activation).map(\.id), ["1-8"])
    }

    // MARK: - Sample chart aspects are tightest-first

    @MainActor
    func testSampleChartAspectsAreSortedByOrbAscending() {
        // `ChartOracle` and `StrongestAspectsCard` assume tightest-first.
        let orbs = BirthChartViewModel.sampleChart().aspects.map(\.orb)
        XCTAssertEqual(orbs, orbs.sorted())
    }

    // MARK: - ChartOracle determinism

    func testStrongestAspectPicksTightestOrbNotFirstElement() {
        // Loosest aspect listed first — the answer must still name the
        // tightest pair (Venus–Mars, orb 1.2).
        let chart = makeChart(
            planets: [planet("Sun", at: 10.0)],
            aspects: [
                .init(planet1: "Sun", planet2: "Moon", type: .square, exactAngle: 90, orb: 6.0),
                .init(planet1: "Venus", planet2: "Mars", type: .trine, exactAngle: 120, orb: 1.2),
            ]
        )
        let answer = ChartOracle.answer(to: .strongestAspect, chart: chart)
        XCTAssertTrue(answer.contains("Venus"), answer)
        XCTAssertTrue(answer.contains("Mars"), answer)
        XCTAssertFalse(answer.contains("Moon"), answer)
    }

    func testDominantElementTieBreaksByCanonicalOrder() {
        // One fire planet + one air planet tie 1–1; fire wins canonically
        // (dictionary iteration order must not decide the answer).
        let chart = makeChart(planets: [
            planet("Mars", at: 10.0), // Aries — fire
            planet("Mercury", at: 65.0), // Gemini — air
        ])
        let answer = ChartOracle.answer(to: .dominantElement, chart: chart)
        XCTAssertTrue(answer.contains("leans fire"), answer)
        XCTAssertTrue(answer.contains("two planets"), answer)
    }

    @MainActor
    func testDominantElementSpellsThePlanetCount() {
        // The count must track the chart (spelled naturally), not a
        // hardcoded "ten".
        let answer = ChartOracle.answer(to: .dominantElement, chart: BirthChartViewModel.sampleChart())
        XCTAssertTrue(answer.contains("of your ten planets"), answer)
    }

    // MARK: - Duplicate planet names must not trap the wheel

    @MainActor
    func testChartWheelRendersWithDuplicatePlanetNames() {
        // A malformed payload with the same planet twice used to trap in
        // `Dictionary(uniqueKeysWithValues:)`. First occurrence wins now.
        let chart = makeChart(
            planets: [
                planet("Sun", at: 10.0),
                planet("Sun", at: 200.0),
                planet("Moon", at: 100.0),
            ],
            aspects: [
                .init(planet1: "Sun", planet2: "Moon", type: .square, exactAngle: 90, orb: 1.0),
            ]
        )
        let renderer = ImageRenderer(
            content: ChartWheelView(chart: chart).frame(width: 300, height: 300)
        )
        XCTAssertNotNil(renderer.uiImage)
    }

    // MARK: - Helpers

    private func planet(_ name: String, at longitude: Double) -> NatalChart.PlanetPosition {
        NatalChart.PlanetPosition(planet: name, longitude: longitude, latitude: 0, isRetrograde: false)
    }

    private func makeChart(
        planets: [NatalChart.PlanetPosition],
        aspects: [NatalChart.Aspect] = []
    ) -> NatalChart {
        NatalChart(
            calculatedAt: Date(timeIntervalSince1970: 0),
            houseSystem: .placidus,
            planets: planets,
            aspects: aspects,
            houses: nil
        )
    }
}
