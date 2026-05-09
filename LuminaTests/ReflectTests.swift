@testable import Lumina
import SwiftData
import XCTest

/// Phase-9 Reflect tests. Word counter, prompt determinism, transit-key
/// shape, and SwiftData round-trip ride CI on every push.
final class ReflectTests: XCTestCase {
    // MARK: - JournalEntry

    func testWordCounterIgnoresExtraWhitespace() {
        XCTAssertEqual(JournalEntry.countWords(in: ""), 0)
        XCTAssertEqual(JournalEntry.countWords(in: "   "), 0)
        XCTAssertEqual(JournalEntry.countWords(in: "one"), 1)
        XCTAssertEqual(JournalEntry.countWords(in: "one two   three"), 3)
        XCTAssertEqual(JournalEntry.countWords(in: "with\nnewlines\nand spaces"), 4)
    }

    @MainActor
    func testApplyBodyUpdatesWordCountAndTimestamp() async throws {
        let entry = JournalEntry(prompt: "Q?", body: "one two")
        let originalUpdatedAt = entry.updatedAt
        XCTAssertEqual(entry.wordCount, 2)

        try await Task.sleep(for: .milliseconds(20))
        entry.apply(body: "now five words go here")
        XCTAssertEqual(entry.wordCount, 5)
        XCTAssertGreaterThan(entry.updatedAt, originalUpdatedAt)
    }

    // MARK: - JournalPromptGenerator

    func testPromptIsDeterministicForSameDate() {
        let date = Date(timeIntervalSince1970: 1_725_000_000)
        let generator = JournalPromptGenerator.shared
        XCTAssertEqual(generator.prompt(for: date), generator.prompt(for: date))
    }

    func testPromptDiffersAcrossDifferentDays() {
        let generator = JournalPromptGenerator.shared
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let day0 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? Date()
        let day7 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 8)) ?? Date()
        XCTAssertNotEqual(
            generator.prompt(for: day0, calendar: calendar),
            generator.prompt(for: day7, calendar: calendar)
        )
    }

    func testTransitKeyShapeIncludesDate() {
        let generator = JournalPromptGenerator.shared
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let date = calendar.date(from: DateComponents(year: 2026, month: 5, day: 8)) ?? Date()
        XCTAssertEqual(generator.transitKey(for: date, calendar: calendar), "date:2026-5-8")
    }

    func testSofterPromptDiffersFromMainPrompt() {
        let date = Date(timeIntervalSince1970: 1_725_000_000)
        let generator = JournalPromptGenerator.shared
        XCTAssertNotEqual(generator.prompt(for: date), generator.softerPrompt(for: date))
    }

    // MARK: - AppPreferences

    @MainActor
    func testAppPreferencesPersistAcrossInstances() {
        let suite = "lumina.tests.prefs.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("could not create test UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suite) }

        let first = AppPreferences(defaults: defaults)
        XCTAssertFalse(first.lockReflectWithFaceID)
        first.lockReflectWithFaceID = true

        let second = AppPreferences(defaults: defaults)
        XCTAssertTrue(second.lockReflectWithFaceID)
    }

    // MARK: - SwiftData round-trip

    @MainActor
    func testJournalEntryRoundTripsThroughInMemoryContainer() throws {
        let schema = Schema([JournalEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        let entry = JournalEntry(prompt: "Q?", body: "one two three")
        context.insert(entry)
        try context.save()

        let descriptor = FetchDescriptor<JournalEntry>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.wordCount, 3)
    }
}
