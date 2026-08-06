@testable import Lumina
import XCTest

/// Tests for the App Store rating gate — pure eligibility logic plus the
/// persistence around it, no views. Every test isolates storage in its own
/// `UserDefaults` suite and pins the day boundary with a UTC calendar, so
/// "three distinct days" never depends on when CI happens to run.
@MainActor
final class ReviewPromptTests: XCTestCase {
    /// 2001-09-09 01:46:40 UTC, and the two days after it.
    private let day1 = Date(timeIntervalSince1970: 1_000_000_000)
    private var day2: Date { day1.addingTimeInterval(86_400) }
    private var day3: Date { day1.addingTimeInterval(2 * 86_400) }

    // MARK: - The pure decision

    func testEligibilityNeedsThreeDays() {
        for count in 0..<ReviewPrompt.requiredEngagedDays {
            XCTAssertFalse(
                ReviewPrompt.isEligible(engagedDayCount: count, askedVersion: nil, currentVersion: "1.0"),
                "\(count) day(s) of use must not earn an ask"
            )
        }
        XCTAssertTrue(
            ReviewPrompt.isEligible(
                engagedDayCount: ReviewPrompt.requiredEngagedDays,
                askedVersion: nil,
                currentVersion: "1.0"
            )
        )
    }

    func testAskingTwiceOnOneVersionIsRefused() {
        XCTAssertFalse(ReviewPrompt.isEligible(engagedDayCount: 30, askedVersion: "1.0", currentVersion: "1.0"))
    }

    func testANewVersionEarnsOneMoreAsk() {
        XCTAssertTrue(ReviewPrompt.isEligible(engagedDayCount: 30, askedVersion: "1.0", currentVersion: "1.1"))
    }

    // MARK: - Counting days

    func testThreeDistinctDaysEarnTheAsk() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let prompt = try makePrompt(defaults: defaults)

        prompt.recordEngagement(on: day1)
        XCTAssertFalse(prompt.isEligible)
        prompt.recordEngagement(on: day2)
        XCTAssertFalse(prompt.isEligible)
        prompt.recordEngagement(on: day3)
        XCTAssertTrue(prompt.isEligible)
        XCTAssertEqual(prompt.engagedDays, ["2001-09-09", "2001-09-10", "2001-09-11"])
    }

    /// Five visits in one evening is one day of engagement. Without this, a
    /// single enthusiastic session would trip the prompt on day one — the
    /// exact behaviour this gate exists to prevent.
    func testRepeatVisitsInOneDayCountOnce() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let prompt = try makePrompt(defaults: defaults)

        for _ in 0..<5 {
            prompt.recordEngagement(on: day1)
        }
        XCTAssertEqual(prompt.engagedDays, ["2001-09-09"])
        XCTAssertFalse(prompt.isEligible)
    }

    func testStoredDaysStayBounded() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let prompt = try makePrompt(defaults: defaults)

        for offset in 0..<40 {
            prompt.recordEngagement(on: day1.addingTimeInterval(Double(offset) * 86_400))
        }
        XCTAssertEqual(prompt.engagedDays.count, ReviewPrompt.storedDayLimit)
        // The cap keeps the *recent* end, so the count still reads as eligible.
        XCTAssertTrue(prompt.isEligible)
    }

    // MARK: - Persistence

    func testMarkAskedPersistsAndBlocksTheSameVersion() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let prompt = try makePrompt(defaults: defaults)

        [day1, day2, day3].forEach { prompt.recordEngagement(on: $0) }
        XCTAssertTrue(prompt.isEligible)
        prompt.markAsked()
        XCTAssertFalse(prompt.isEligible)

        // A relaunch reads the same answer back out of storage.
        let rehydrated = try makePrompt(defaults: defaults)
        XCTAssertEqual(rehydrated.askedVersion, "1.0")
        XCTAssertFalse(rehydrated.isEligible)

        // …and the next release may ask once more.
        let nextRelease = try makePrompt(defaults: defaults, version: "1.1")
        XCTAssertTrue(nextRelease.isEligible)
    }

    func testClearErasesTheRecord() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let prompt = try makePrompt(defaults: defaults)

        [day1, day2, day3].forEach { prompt.recordEngagement(on: $0) }
        prompt.markAsked()
        prompt.clear()

        XCTAssertTrue(prompt.engagedDays.isEmpty)
        XCTAssertNil(prompt.askedVersion)
        XCTAssertFalse(prompt.isEligible)

        let reloaded = try makePrompt(defaults: defaults)
        XCTAssertFalse(reloaded.isEligible, "cleared state must not survive a relaunch")
    }

    // MARK: - Helpers

    private func makeDefaults() throws -> (UserDefaults, String) {
        let suite = "lumina.tests.reviewprompt.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        return (defaults, suite)
    }

    private func makePrompt(defaults: UserDefaults, version: String = "1.0") throws -> ReviewPrompt {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "UTC"))
        return ReviewPrompt(defaults: defaults, calendar: calendar, version: version)
    }
}
