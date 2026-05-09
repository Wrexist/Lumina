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
    func testActivationFromSampleChartLightsUpAtLeastOneCenter() {
        let chart = BirthChartViewModel.sampleChart()
        let activation = HumanDesignActivation.compute(from: chart)
        XCTAssertEqual(activation.personality.count, 10, "one activation per natal planet")
        XCTAssertFalse(activation.activatedGates.isEmpty)
        XCTAssertFalse(activation.definedCenters.isEmpty)
        // Every activated gate must be owned by exactly one defined center.
        for gate in activation.activatedGates {
            let owner = HumanDesignCenter.allCases.first { $0.gates.contains(gate) }
            XCTAssertNotNil(owner, "gate \(gate) has no owning center")
            XCTAssertTrue(activation.definedCenters.contains(owner ?? .head))
        }
    }
}
