@testable import Lumina
import XCTest

/// Tests for the deterministic daily "know your chart" quiz engine — same
/// (chart, seed) must always produce the same questions, every question must
/// be answerable from the real chart, and the score copy must stay warm.
final class ChartQuizTests: XCTestCase {
    // MARK: - Determinism

    @MainActor
    func testSameChartAndSeedProduceIdenticalQuestions() {
        let chart = BirthChartViewModel.sampleChart()
        let first = ChartQuizEngine.questions(from: chart, seed: 42)
        let second = ChartQuizEngine.questions(from: chart, seed: 42)
        XCTAssertEqual(first, second)
        XCTAssertFalse(first.isEmpty)
    }

    @MainActor
    func testDifferentSeedsChangeTheSelectionAcrossSeveralSeeds() {
        let chart = BirthChartViewModel.sampleChart()
        let baseline = ChartQuizEngine.questions(from: chart, seed: 1)
        let seeds: [UInt64] = [2, 3, 4, 5, 6, 7, 8]
        let anyDiffers = seeds.contains { ChartQuizEngine.questions(from: chart, seed: $0) != baseline }
        XCTAssertTrue(anyDiffers, "seven other seeds should not all reproduce seed 1's questions")
    }

    func testSeededGeneratorIsDeterministic() {
        var first = SeededGenerator(seed: 7)
        var second = SeededGenerator(seed: 7)
        for _ in 0..<8 {
            XCTAssertEqual(first.next(), second.next())
        }
    }

    // MARK: - Question integrity

    @MainActor
    func testEveryQuestionHasInBoundsAnswerAndDistinctOptions() {
        let chart = BirthChartViewModel.sampleChart()
        for seed: UInt64 in 1...20 {
            for question in ChartQuizEngine.questions(from: chart, count: 4, seed: seed) {
                XCTAssertTrue(question.options.indices.contains(question.answerIndex), question.prompt)
                XCTAssertEqual(Set(question.options).count, question.options.count, question.prompt)
                XCTAssertFalse(question.prompt.isEmpty)
                XCTAssertFalse(question.insight.isEmpty, question.prompt)
            }
        }
    }

    @MainActor
    func testSignQuestionAnswerMatchesTheChart() throws {
        let chart = BirthChartViewModel.sampleChart()
        for seed: UInt64 in 1...20 {
            let questions = ChartQuizEngine.questions(from: chart, count: 4, seed: seed)
            for question in questions where question.prompt.hasPrefix("Which sign is your ") {
                let name = question.prompt
                    .replacingOccurrences(of: "Which sign is your ", with: "")
                    .replacingOccurrences(of: "?", with: "")
                let planet = try XCTUnwrap(chart.planets.first { $0.planet == name }, name)
                XCTAssertEqual(
                    question.options[question.answerIndex],
                    ChartGlyphs.sign(forLongitude: planet.longitude)
                )
            }
        }
    }

    @MainActor
    func testRetrogradeQuestionOnlyOffersARetrogradeAsTheAnswer() {
        let chart = BirthChartViewModel.sampleChart()
        let retrogradeNames = Set(chart.planets.filter(\.isRetrograde).map(\.planet))
        let prompt = "Which of these planets is retrograde in your chart?"
        var sawTemplate = false
        for seed: UInt64 in 1...20 {
            let questions = ChartQuizEngine.questions(from: chart, count: 4, seed: seed)
            for question in questions where question.prompt == prompt {
                sawTemplate = true
                XCTAssertTrue(retrogradeNames.contains(question.options[question.answerIndex]))
                for (offset, option) in question.options.enumerated() where offset != question.answerIndex {
                    XCTAssertFalse(retrogradeNames.contains(option), "distractor \(option) is retrograde")
                }
            }
        }
        XCTAssertTrue(sawTemplate, "sample chart qualifies for the retrograde template")
    }

    @MainActor
    func testTightestAspectQuestionNamesTheMinimumOrbPair() {
        // Sample chart's tightest aspect is Mercury–Venus (orb 2.7).
        let chart = BirthChartViewModel.sampleChart()
        let prompt = "Your tightest aspect is between which pair?"
        var sawTemplate = false
        for seed: UInt64 in 1...20 {
            let questions = ChartQuizEngine.questions(from: chart, count: 4, seed: seed)
            for question in questions where question.prompt == prompt {
                sawTemplate = true
                XCTAssertEqual(question.options[question.answerIndex], "Mercury & Venus")
            }
        }
        XCTAssertTrue(sawTemplate, "sample chart qualifies for the aspect template")
    }

    @MainActor
    func testElementQuestionAnswerMatchesTheTally() {
        // Sample chart tally: Water 4 (Moon, Venus, Jupiter, Pluto), Earth 3,
        // Air 2, Fire 1 — Water leads.
        let chart = BirthChartViewModel.sampleChart()
        let prompt = "Which element leads your chart?"
        var sawTemplate = false
        for seed: UInt64 in 1...20 {
            let questions = ChartQuizEngine.questions(from: chart, count: 4, seed: seed)
            for question in questions where question.prompt == prompt {
                sawTemplate = true
                XCTAssertEqual(question.options[question.answerIndex], "Water")
            }
        }
        XCTAssertTrue(sawTemplate, "sample chart qualifies for the element template")
    }

    func testChartWithoutAspectsOrRetrogradesReturnsFewerQuestions() {
        let chart = NatalChart(
            calculatedAt: .now,
            houseSystem: .placidus,
            planets: [
                .init(planet: "Sun", longitude: 15, latitude: 0, isRetrograde: false),
                .init(planet: "Moon", longitude: 135, latitude: 0, isRetrograde: false),
            ],
            aspects: [],
            houses: nil
        )
        let questions = ChartQuizEngine.questions(from: chart, count: 4, seed: 3)
        XCTAssertEqual(questions.count, 2, "only the sign and element templates qualify")
    }

    // MARK: - Daily seed

    func testDailySeedIsStableWithinADayAndChangesAcrossDays() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "UTC"))
        let morning = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 2, hour: 8)))
        let evening = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 2, hour: 23)))
        let tomorrow = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 3, hour: 8)))
        XCTAssertEqual(
            ChartQuizEngine.dailySeed(for: morning, calendar: calendar),
            ChartQuizEngine.dailySeed(for: evening, calendar: calendar)
        )
        XCTAssertNotEqual(
            ChartQuizEngine.dailySeed(for: morning, calendar: calendar),
            ChartQuizEngine.dailySeed(for: tomorrow, calendar: calendar)
        )
    }

    func testDayStringUsesTheStorageFormat() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "UTC"))
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 2)))
        XCTAssertEqual(ChartQuizEngine.dayString(for: date, calendar: calendar), "2026-07-02")
    }

    // MARK: - Verdict copy

    func testVerdictIsNonEmptyForEveryScoreCombination() {
        for total in 0...4 {
            for correct in 0...total {
                let verdict = ChartQuizEngine.verdict(correct: correct, total: total)
                XCTAssertFalse(verdict.isEmpty, "verdict missing for \(correct)/\(total)")
            }
        }
    }

    func testVerdictStaysWarmAtEveryScore() {
        XCTAssertEqual(ChartQuizEngine.verdict(correct: 3, total: 3), "You know your sky. ✦")
        XCTAssertEqual(ChartQuizEngine.verdict(correct: 2, total: 3), "Close to your chart — one surprise today.")
        XCTAssertEqual(
            ChartQuizEngine.verdict(correct: 0, total: 3),
            "Your chart still has secrets for you — the wheel above knows them all."
        )
        XCTAssertEqual(
            ChartQuizEngine.verdict(correct: 1, total: 3),
            "A few surprises today — your chart clearly still has stories for you."
        )
    }
}
