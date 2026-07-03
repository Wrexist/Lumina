@testable import Lumina
import SwiftData
import XCTest

/// Regression tests for the 2026-07 hub polish batch: the reflection-Moment
/// honesty gate (empty entries earn nothing), the reflection backfill on
/// upgrade, and the Daily Reveal midnight-rollover day key.
final class HubPolishFixTests: XCTestCase {
    /// 2001-09-09 01:46:40 UTC — a fixed instant so day math never depends on
    /// when the suite runs.
    private let fixedDate = Date(timeIntervalSince1970: 1_000_000_000)

    // MARK: - Honesty: only real writing counts

    /// The Reflect surfaces count reflection Moments with
    /// `#Predicate<JournalEntry> { $0.wordCount > 0 }`. A blank entry the user
    /// opened but never wrote in must not be counted, or a Moment would unlock
    /// on empty text.
    @MainActor
    func testWrittenEntryPredicateCountsOnlyNonEmptyEntries() throws {
        let context = try makeContext()
        context.insert(JournalEntry(prompt: "Q?", body: ""))
        context.insert(JournalEntry(prompt: "Q?", body: "   "))
        context.insert(JournalEntry(prompt: "Q?", body: "one two three"))
        context.insert(JournalEntry(prompt: "Q?", body: "written"))
        try context.save()

        let all = try context.fetchCount(FetchDescriptor<JournalEntry>())
        let written = try context.fetchCount(
            FetchDescriptor<JournalEntry>(predicate: #Predicate { $0.wordCount > 0 })
        )
        XCTAssertEqual(all, 4)
        XCTAssertEqual(written, 2, "blank and whitespace-only entries must not count")
    }

    /// A freshly created entry is empty (`wordCount == 0`), so the written
    /// count stays 0 and no reflection Moment unlocks — the fix's whole point.
    @MainActor
    func testEmptyEntryDoesNotUnlockFirstReflection() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = MomentsStore(defaults: defaults)

        XCTAssertFalse(store.recordReflection(totalCount: 0), "no writing, no Moment")
        XCTAssertFalse(store.isUnlocked(.firstReflection))
    }

    // MARK: - Backfill on upgrade

    /// Backfill replays the written count on hub appearance: an upgrading user
    /// with existing pages earns their reflection Moments, and a repeat pass is
    /// a silent no-op (so no haptic replays).
    @MainActor
    func testBackfillUnlocksExistingThenIsIdempotent() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = MomentsStore(defaults: defaults)

        XCTAssertTrue(store.recordReflection(totalCount: 12), "backfilling 12 pages unlocks 1 and 10")
        XCTAssertTrue(store.isUnlocked(.firstReflection))
        XCTAssertTrue(store.isUnlocked(.tenReflections))
        XCTAssertFalse(store.isUnlocked(.twentyFiveReflections))
        XCTAssertFalse(store.recordReflection(totalCount: 12), "a second backfill pass unlocks nothing")
    }

    // MARK: - Daily Reveal midnight rollover

    func testDayKeyFormatIsZeroPadded() {
        XCTAssertEqual(DailyRevealState.dayKey(for: fixedDate, calendar: utcCalendar()), "2001-09-09")
    }

    /// The key flips at the calendar-day boundary — the trigger the Today view
    /// uses (via `.id`) to re-veil the reading past midnight.
    func testDayKeyChangesAcrossMidnight() {
        let calendar = utcCalendar()
        let lateSameDay = fixedDate.addingTimeInterval(22 * 3_600)
        let nextDay = fixedDate.addingTimeInterval(24 * 3_600)
        XCTAssertEqual(DailyRevealState.dayKey(for: lateSameDay, calendar: calendar), "2001-09-09")
        XCTAssertEqual(DailyRevealState.dayKey(for: nextDay, calendar: calendar), "2001-09-10")
    }

    /// The static key matches what the instance persists as `lastRevealedDay`,
    /// so a view keyed on `dayKey` and the reveal store never disagree.
    @MainActor
    func testDayKeyMatchesInstanceRevealDay() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let calendar = utcCalendar()
        let state = DailyRevealState(defaults: defaults, calendar: calendar)
        state.markRevealed(on: fixedDate)
        XCTAssertEqual(state.lastRevealedDay, DailyRevealState.dayKey(for: fixedDate, calendar: calendar))
    }

    // MARK: - Helpers

    @MainActor
    private func makeContext() throws -> ModelContext {
        let schema = Schema([JournalEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    private func makeDefaults() throws -> (defaults: UserDefaults, suite: String) {
        let suite = "lumina.tests.hubpolish.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite), "could not create test UserDefaults suite")
        return (defaults, suite)
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }
}
