@testable import Lumina
import XCTest

/// Tests for `MomentsStore`: unlock-once semantics, newest-first ordering,
/// the latestUnseen/markSeen flow, moon-phase witnessing with the
/// eighth-phase auto-unlock, reflection thresholds, and persistence across
/// store instances. Every test gets its own UserDefaults suite.
@MainActor
final class MomentsStoreTests: XCTestCase {
    private func makeDefaults() throws -> (defaults: UserDefaults, suite: String) {
        let suite = "lumina.tests.moments.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite), "could not create test UserDefaults suite")
        return (defaults, suite)
    }

    // MARK: - Unlock semantics

    func testUnlockReturnsTrueOnlyTheFirstTime() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = MomentsStore(defaults: defaults)

        XCTAssertFalse(store.isUnlocked(.firstChart))
        XCTAssertTrue(store.unlock(.firstChart))
        XCTAssertTrue(store.isUnlocked(.firstChart))
        // A second unlock is a no-op — callers rely on `false` to avoid
        // replaying celebration haptics.
        XCTAssertFalse(store.unlock(.firstChart))
    }

    func testUnlockedIsSortedNewestFirstWithDates() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = MomentsStore(defaults: defaults)

        let base = Date(timeIntervalSince1970: 1_750_000_000)
        store.unlock(.firstChart, at: base)
        store.unlock(.firstReflection, at: base.addingTimeInterval(60))
        store.unlock(.firstFriend, at: base.addingTimeInterval(120))

        XCTAssertEqual(store.unlocked.map(\.moment), [.firstFriend, .firstReflection, .firstChart])
        XCTAssertEqual(store.unlocked.first?.date, base.addingTimeInterval(120))
        XCTAssertEqual(store.unlocked.last?.date, base)
    }

    // MARK: - Seen flow

    func testLatestUnseenSurfacesEachUnlockExactlyOnce() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = MomentsStore(defaults: defaults)

        XCTAssertNil(store.latestUnseen)

        let base = Date(timeIntervalSince1970: 1_750_000_000)
        store.unlock(.firstChart, at: base)
        store.unlock(.firstReflection, at: base.addingTimeInterval(60))

        // Newest unseen wins; marking it seen falls back to the older one.
        XCTAssertEqual(store.latestUnseen, .firstReflection)
        store.markSeen(.firstReflection)
        XCTAssertEqual(store.latestUnseen, .firstChart)
        store.markSeen(.firstChart)
        XCTAssertNil(store.latestUnseen)
    }

    // MARK: - Moon phases

    func testWitnessMoonPhaseGrowsSetAndIgnoresDuplicatesAndUnknowns() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = MomentsStore(defaults: defaults)

        XCTAssertTrue(store.witnessMoonPhase("Full Moon"))
        XCTAssertFalse(store.witnessMoonPhase("Full Moon"), "duplicate phases must not grow the set")
        XCTAssertFalse(store.witnessMoonPhase("Blood Moon"), "unknown phase names are ignored")
        XCTAssertEqual(store.witnessedPhases, ["Full Moon"])
    }

    func testEighthDistinctPhaseAutoUnlocksAllMoonPhases() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = MomentsStore(defaults: defaults)

        let phases = [
            "New Moon", "Waxing Crescent", "First Quarter", "Waxing Gibbous",
            "Full Moon", "Waning Gibbous", "Last Quarter"
        ]
        for phase in phases {
            XCTAssertTrue(store.witnessMoonPhase(phase))
        }
        XCTAssertFalse(store.isUnlocked(.allMoonPhases), "seven phases are not enough")

        XCTAssertTrue(store.witnessMoonPhase("Waning Crescent"))
        XCTAssertTrue(store.isUnlocked(.allMoonPhases))
        XCTAssertEqual(store.witnessedPhases.count, 8)
    }

    // MARK: - Reflection thresholds

    func testRecordReflectionUnlocksAtOneTenAndTwentyFive() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = MomentsStore(defaults: defaults)

        XCTAssertTrue(store.recordReflection(totalCount: 1))
        XCTAssertTrue(store.isUnlocked(.firstReflection))
        XCTAssertFalse(store.recordReflection(totalCount: 5), "no new milestone between thresholds")

        XCTAssertTrue(store.recordReflection(totalCount: 10))
        XCTAssertTrue(store.isUnlocked(.tenReflections))
        XCTAssertFalse(store.isUnlocked(.twentyFiveReflections))

        // Jumping straight past 25 unlocks everything that applies.
        XCTAssertTrue(store.recordReflection(totalCount: 25))
        XCTAssertTrue(store.isUnlocked(.twentyFiveReflections))
    }

    // MARK: - Persistence

    func testStateRoundTripsAcrossStoreInstances() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }

        let unlockDate = Date(timeIntervalSince1970: 1_750_000_000)
        let first = MomentsStore(defaults: defaults)
        first.unlock(.firstChart, at: unlockDate)
        first.markSeen(.firstChart)
        first.witnessMoonPhase("New Moon")

        let second = MomentsStore(defaults: defaults)
        XCTAssertTrue(second.isUnlocked(.firstChart))
        XCTAssertEqual(second.unlocked.first?.date, unlockDate)
        XCTAssertNil(second.latestUnseen, "seen set must persist too")
        XCTAssertEqual(second.witnessedPhases, ["New Moon"])
        XCTAssertFalse(second.unlock(.firstChart), "persisted unlocks stay unlock-once")
    }
}
