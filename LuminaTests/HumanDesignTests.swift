@testable import Lumina
import XCTest

/// Phase-8 Human Design tests. Mandala gate-by-longitude correctness,
/// gate-line subdivision, center ownership exhaustivity, and the
/// natal-chart → activation pipeline.
final class HumanDesignTests: XCTestCase {
    // MARK: - Mandala

    func testMandalaSequenceHasExactlySixtyFourGates() {
        XCTAssertEqual(HumanDesignMandala.sequence.count, 64)
        XCTAssertEqual(Set(HumanDesignMandala.sequence).count, 64, "no duplicates")
        XCTAssertEqual(Set(HumanDesignMandala.sequence), Set(1...64))
    }

    func testFirstGateAtZeroOffsetIsGateTwentyFive() {
        // Gate 25 begins at the configured offset (3°52'30" Aries).
        let gate = HumanDesignMandala.gate(forLongitude: HumanDesignMandala.zeroOffset + 0.001)
        XCTAssertEqual(gate, 25)
    }

    func testGateWrapsAround360() {
        let zeroDegree = HumanDesignMandala.gate(forLongitude: 0)
        let threeSixty = HumanDesignMandala.gate(forLongitude: 360)
        XCTAssertEqual(zeroDegree, threeSixty)
    }

    func testLineSubdividesGateIntoSix() {
        // First slice of Gate 25 is line 1, last slice is line 6.
        let firstLine = HumanDesignMandala.line(forLongitude: HumanDesignMandala.zeroOffset + 0.01)
        let lastLine = HumanDesignMandala.line(
            forLongitude: HumanDesignMandala.zeroOffset + HumanDesignMandala.gateWidth - 0.01
        )
        XCTAssertEqual(firstLine, 1)
        XCTAssertEqual(lastLine, 6)
    }

    func testLineStaysWithinOneToSix() {
        for degree in stride(from: 0.0, to: 360.0, by: 0.5) {
            let line = HumanDesignMandala.line(forLongitude: degree)
            XCTAssertGreaterThanOrEqual(line, 1)
            XCTAssertLessThanOrEqual(line, 6)
        }
    }

    // MARK: - Centers

    func testCentersOwnExactlySixtyFourGatesDisjointly() {
        var seen = Set<Int>()
        for center in HumanDesignCenter.allCases {
            for gate in center.gates {
                XCTAssertFalse(seen.contains(gate), "gate \(gate) appears in two centers")
                seen.insert(gate)
            }
        }
        XCTAssertEqual(seen.count, 64)
        XCTAssertEqual(seen, Set(1...64))
    }

    // MARK: - Activation

    @MainActor
    func testActivationCentersFollowTheChannelRule() {
        let chart = BirthChartViewModel.sampleChart()
        let activation = HumanDesignActivation.compute(from: chart)
        XCTAssertEqual(activation.personality.count, 11, "one per natal planet, plus the Earth")
        XCTAssertFalse(activation.activatedGates.isEmpty)
        // A center is defined only by a complete channel — never by a lone
        // (hanging) gate. The defined set must be exactly the endpoints of
        // the defined channels.
        let expected = Set(
            HumanDesignChannels.defined(gates: activation.activatedGates)
                .flatMap { [$0.centerA, $0.centerB] }
        )
        XCTAssertEqual(activation.definedCenters, expected)
    }

    /// The Earth is a personality activation in every real Human Design chart
    /// and is always exactly opposite the Sun. It was missing, which cost
    /// every user one of their eleven chances at completing a channel — on a
    /// paid feature that renders an all-open bodygraph when none complete.
    @MainActor
    func testTheEarthIsActivatedOppositeTheSun() throws {
        let chart = BirthChartViewModel.sampleChart()
        let activation = HumanDesignActivation.compute(from: chart)

        let sun = try XCTUnwrap(chart.planets.first { $0.planet == "Sun" })
        let earth = try XCTUnwrap(activation.personality.first { $0.planet == "Earth" })
        XCTAssertEqual(earth.gate, HumanDesignMandala.gate(forLongitude: sun.longitude + 180))
        XCTAssertEqual(earth.line, HumanDesignMandala.line(forLongitude: sun.longitude + 180))

        // Exactly one Earth, and it doesn't displace any natal body.
        XCTAssertEqual(activation.personality.filter { $0.planet == "Earth" }.count, 1)
        for planet in chart.planets {
            XCTAssertTrue(
                activation.personality.contains { $0.planet == planet.planet },
                "\(planet.planet) lost its activation"
            )
        }
    }
}
