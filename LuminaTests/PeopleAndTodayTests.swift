@testable import Lumina
import SwiftData
import XCTest

/// Phase-7/10 People + Phase-3 Today tests. Compatibility scoring,
/// `Friend` SwiftData round-trip, deterministic Today headlines.
final class PeopleAndTodayTests: XCTestCase {
    // MARK: - CompatibilityScorer

    func testScoreIsSymmetric() {
        let aprilFirst = makeDate(year: 1990, month: 4, day: 1)
        let octoberTenth = makeDate(year: 1992, month: 10, day: 10)
        let forward = CompatibilityScorer.score(aprilFirst, octoberTenth)
        let reverse = CompatibilityScorer.score(octoberTenth, aprilFirst)
        XCTAssertEqual(forward, reverse, "compatibility must be order-independent")
    }

    func testScoreStaysInRange() {
        for year in 1970...2000 {
            for month in 1...12 {
                let date = makeDate(year: year, month: month, day: 15)
                let other = makeDate(year: 1990, month: 6, day: 15)
                let score = CompatibilityScorer.score(date, other)
                XCTAssertGreaterThanOrEqual(score, 0)
                XCTAssertLessThanOrEqual(score, 100)
            }
        }
    }

    func testSameElementOutScoresOppositeElement() {
        let aries = makeDate(year: 1990, month: 4, day: 1)
        let leo = makeDate(year: 1990, month: 8, day: 1)
        let cancer = makeDate(year: 1990, month: 7, day: 1)
        let sameFire = CompatibilityScorer.score(aries, leo)
        let fireWater = CompatibilityScorer.score(aries, cancer)
        XCTAssertGreaterThan(sameFire, fireWater)
    }

    func testLabelMappingCovers0To100() {
        XCTAssertEqual(CompatibilityScorer.Label(score: 95).displayName, "Magnetic")
        XCTAssertEqual(CompatibilityScorer.Label(score: 70).displayName, "Harmonious")
        XCTAssertEqual(CompatibilityScorer.Label(score: 50).displayName, "Stimulating")
        XCTAssertEqual(CompatibilityScorer.Label(score: 10).displayName, "Challenging")
    }

    // MARK: - Synastry-weighted score (real cross-aspects)

    func testSynastryScoreEmptyIsNeutral() {
        XCTAssertEqual(CompatibilityScorer.score(fromSynastry: []), 50)
    }

    func testHarmoniousAspectsScoreAboveHardAspects() {
        let harmonious = [synAspect("Sun", "Moon", .trine, orb: 1), synAspect("Venus", "Mars", .sextile, orb: 1)]
        let hard = [synAspect("Sun", "Moon", .square, orb: 1), synAspect("Venus", "Mars", .opposition, orb: 1)]
        XCTAssertGreaterThan(CompatibilityScorer.score(fromSynastry: harmonious), 50)
        XCTAssertLessThan(CompatibilityScorer.score(fromSynastry: hard), 50)
        XCTAssertGreaterThan(
            CompatibilityScorer.score(fromSynastry: harmonious),
            CompatibilityScorer.score(fromSynastry: hard)
        )
    }

    func testTighterAspectsCountMore() {
        let tight = [synAspect("Sun", "Moon", .trine, orb: 0.5)]
        let wide = [synAspect("Sun", "Moon", .trine, orb: 9.5)]
        XCTAssertGreaterThan(
            CompatibilityScorer.score(fromSynastry: tight),
            CompatibilityScorer.score(fromSynastry: wide)
        )
    }

    func testRelationshipPlanetsWeightedMore() {
        let personal = [synAspect("Venus", "Mars", .trine, orb: 1)]
        let outer = [synAspect("Saturn", "Jupiter", .trine, orb: 1)]
        XCTAssertGreaterThan(
            CompatibilityScorer.score(fromSynastry: personal),
            CompatibilityScorer.score(fromSynastry: outer)
        )
    }

    func testSynastryScoreStaysInRange() {
        let flood = Array(repeating: synAspect("Venus", "Mars", .trine, orb: 0.5), count: 60)
        let score = CompatibilityScorer.score(fromSynastry: flood)
        XCTAssertGreaterThanOrEqual(score, 0)
        XCTAssertLessThanOrEqual(score, 100)
    }

    private func synAspect(_ a: String, _ b: String, _ type: AspectType, orb: Double) -> SynastryAspect {
        SynastryAspect(planetA: a, planetB: b, type: type, exactAngle: 0, orb: orb)
    }

    // MARK: - Friend round-trip

    @MainActor
    func testFriendRoundTripsThroughInMemoryContainer() throws {
        let schema = Schema([Friend.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        let friend = Friend(
            name: "Sam",
            birthDate: makeDate(year: 1992, month: 7, day: 12),
            birthPlaceName: "Athens",
            birthLatitude: 37.98,
            birthLongitude: 23.72,
            birthTimeZoneIdentifier: "Europe/Athens",
            source: .manual,
            compatibilityScore: 73
        )
        context.insert(friend)
        try context.save()

        let descriptor = FetchDescriptor<Friend>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Sam")
        XCTAssertEqual(fetched.first?.compatibilityScore, 73)

        // makeBirthData round-trip — all coords present.
        let birthData = fetched.first?.makeBirthData()
        XCTAssertNotNil(birthData)
        XCTAssertEqual(birthData?.timeZoneIdentifier, "Europe/Athens")
    }

    @MainActor
    func testFriendMakeBirthDataNilWhenCoordsMissing() {
        let friend = Friend(name: "Anonymous", birthDate: .now)
        XCTAssertNil(friend.makeBirthData())
    }

    // MARK: - TodayViewModel.todayLines (real transits → headline + rows)

    @MainActor
    func testTodayLinesEmptyWhenNoTransits() {
        let lines = TodayViewModel.todayLines(from: [])
        XCTAssertNil(lines.headline)
        XCTAssertTrue(lines.secondary.isEmpty)
    }

    @MainActor
    func testTodayLinesUseTightestAsHeadlineAndCapSecondary() {
        let transits = [
            TransitReading(transiting: "Pluto", natal: "Mercury", type: .trine, exactAngle: 120, orb: 0.4, applying: false),
            TransitReading(transiting: "Venus", natal: "Venus", type: .sextile, exactAngle: 60, orb: 0.5, applying: true),
            TransitReading(transiting: "Saturn", natal: "Neptune", type: .square, exactAngle: 90, orb: 1.3, applying: true),
            TransitReading(transiting: "Moon", natal: "Jupiter", type: .opposition, exactAngle: 180, orb: 1.3, applying: false),
            TransitReading(transiting: "Mars", natal: "Sun", type: .conjunction, exactAngle: 0, orb: 2, applying: true),
        ]
        let lines = TodayViewModel.todayLines(from: transits)
        XCTAssertEqual(lines.headline, "Pluto trine your Mercury, easing")
        XCTAssertEqual(lines.secondary.count, 3, "secondary is capped at 3")
        XCTAssertEqual(lines.secondary.first, "Venus sextile your Venus, building")
    }

    // MARK: - Helpers

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}
