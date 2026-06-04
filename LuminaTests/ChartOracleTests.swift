@testable import Lumina
import XCTest

/// Tests for the deterministic "ask your chart" engine — every question must
/// return a grounded, non-empty answer read from the real chart.
final class ChartOracleTests: XCTestCase {
    @MainActor
    func testEveryQuestionProducesAGroundedAnswer() {
        let chart = BirthChartViewModel.sampleChart()
        for question in ChartQuestion.allCases {
            let answer = ChartOracle.answer(to: question, chart: chart)
            XCTAssertGreaterThan(answer.count, 20, "\(question) answer too short")
            XCTAssertFalse(answer.contains("still loading"), "\(question) hit the loading fallback")
        }
    }

    @MainActor
    func testBigThreeNamesTheLuminaries() {
        let answer = ChartOracle.answer(to: .bigThree, chart: BirthChartViewModel.sampleChart())
        XCTAssertTrue(answer.contains("Sun"))
        XCTAssertTrue(answer.contains("Moon"))
    }

    @MainActor
    func testDominantElementNamesAnElement() {
        let answer = ChartOracle.answer(to: .dominantElement, chart: BirthChartViewModel.sampleChart())
        XCTAssertTrue(["fire", "earth", "air", "water"].contains { answer.contains($0) })
    }

    @MainActor
    func testRetrogradesAnswerIsCoherent() {
        let answer = ChartOracle.answer(to: .retrogrades, chart: BirthChartViewModel.sampleChart())
        XCTAssertTrue(answer.contains("retrograde") || answer.contains("forward"))
    }

    @MainActor
    func testStrongestAspectIsGrounded() {
        let answer = ChartOracle.answer(to: .strongestAspect, chart: BirthChartViewModel.sampleChart())
        XCTAssertTrue(answer.contains("Your") || answer.contains("on their own"))
    }

    func testEachQuestionHasAStableID() {
        XCTAssertEqual(Set(ChartQuestion.allCases.map(\.id)).count, ChartQuestion.allCases.count)
    }
}
