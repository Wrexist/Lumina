@testable import Lumina
import XCTest

/// Account deletion (Apple 5.1.1(v)) must leave nothing of the deleted account
/// on the device. These pin the `clear()` seams the teardown depends on, and
/// the load-time reconciliation that keeps stored progression state honest.
@MainActor
final class AccountEraseStoreTests: XCTestCase {
    private func makeDefaults() throws -> UserDefaults {
        let suite = "lumina.tests.erase.\(UUID().uuidString)"
        return try XCTUnwrap(UserDefaults(suiteName: suite))
    }

    /// Onboarding gated its Continue button on a name and then discarded it.
    /// Now that it's kept, it has to survive a relaunch and disappear with the
    /// account — it's personal data the user handed over, not a toggle.
    func testDisplayNamePersistsAcrossRelaunchAndClearsOnReset() throws {
        let defaults = try makeDefaults()
        let preferences = AppPreferences(defaults: defaults)
        XCTAssertEqual(preferences.displayName, "", "no name until one is given")

        preferences.displayName = "Sam"
        XCTAssertEqual(AppPreferences(defaults: defaults).displayName, "Sam", "must survive a relaunch")

        preferences.displayName = ""
        XCTAssertEqual(AppPreferences(defaults: defaults).displayName, "")
    }

    /// Export is the mirror image of deletion: the same set of stores, read
    /// instead of cleared. It has to include the personal fields (GDPR
    /// Art. 20 portability) and must not include anything we tell the user we
    /// don't keep.
    func testDataExportCarriesThePersonalFieldsAndNothingSecret() throws {
        let entry = JournalEntry(
            date: Date(timeIntervalSince1970: 1_000_000),
            prompt: "What are you avoiding?",
            body: "Writing this down.",
            transitKey: "sun-square-saturn"
        )
        let friend = Friend(
            name: "Alex",
            birthDate: Date(timeIntervalSince1970: 500_000),
            source: .manual
        )

        let export = LuminaDataExport.make(journalEntries: [entry], friends: [friend])
        let json = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: try export.encoded()) as? [String: Any]
        )

        XCTAssertEqual(json["formatVersion"] as? Int, 1)
        let entries = try XCTUnwrap(json["journalEntries"] as? [[String: Any]])
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?["body"] as? String, "Writing this down.")
        XCTAssertEqual(entries.first?["prompt"] as? String, "What are you avoiding?")
        let people = try XCTUnwrap(json["people"] as? [[String: Any]])
        XCTAssertEqual(people.first?["name"] as? String, "Alex")
        // The file states its own limits, so the recipient knows what's absent.
        XCTAssertFalse((json["notIncluded"] as? [String] ?? []).isEmpty)

        // Nothing resembling a credential may appear anywhere in the archive.
        let raw = try XCTUnwrap(String(bytes: try export.encoded(), encoding: .utf8)).lowercased()
        for forbidden in ["x-lumina-secret", "sk-ant-", "appl_", "bearer ", "authtoken"] {
            XCTAssertFalse(raw.contains(forbidden), "export leaked \(forbidden)")
        }
    }

    func testChartDiscoveryClearEmptiesProgress() throws {
        let defaults = try makeDefaults()
        let discovery = ChartDiscovery(defaults: defaults)
        XCTAssertTrue(discovery.markExplored("Sun"))
        XCTAssertTrue(discovery.celebrateCompletionIfNeeded())

        discovery.clear()
        XCTAssertEqual(discovery.exploredCount, 0)
        XCTAssertFalse(discovery.isExplored("Sun"))
        // A fresh store on the same suite starts empty and can celebrate again.
        let reloaded = ChartDiscovery(defaults: defaults)
        XCTAssertEqual(reloaded.exploredCount, 0)
        XCTAssertTrue(reloaded.celebrateCompletionIfNeeded())
    }

    func testMomentsStoreClearEmptiesEverything() throws {
        let defaults = try makeDefaults()
        let store = MomentsStore(defaults: defaults)
        store.unlock(.firstChart)
        store.markSeen(.firstChart)
        _ = store.witnessMoonPhase("Full Moon")

        store.clear()
        XCTAssertFalse(store.isUnlocked(.firstChart))
        XCTAssertTrue(store.unlocked.isEmpty)
        XCTAssertTrue(store.witnessedPhases.isEmpty)
        XCTAssertNil(store.latestUnseen)
        // Nothing survives into a reloaded store.
        let reloaded = MomentsStore(defaults: defaults)
        XCTAssertTrue(reloaded.unlocked.isEmpty)
        XCTAssertTrue(reloaded.witnessedPhases.isEmpty)
    }

    func testWitnessedPhasesDropsUnknownStoredNamesOnLoad() throws {
        let defaults = try makeDefaults()
        // Simulate a store written by an older build with a since-renamed name.
        defaults.set(["Full Moon", "Blood Moon", "Waxing Crescent"], forKey: "luminaMomentsWitnessedMoonPhases")
        let store = MomentsStore(defaults: defaults)
        XCTAssertEqual(store.witnessedPhases, ["Full Moon", "Waxing Crescent"])
        XCTAssertFalse(store.witnessedPhases.contains("Blood Moon"))
    }

    func testWidgetSharedStoreClearRemovesSnapshot() {
        let snapshot = WidgetSnapshot(
            sunSign: "Gemini", moonSign: "Pisces", risingSign: "Libra", headline: "Gemini Sun"
        )
        WidgetSharedStore.write(snapshot)
        XCTAssertNotNil(WidgetSharedStore.read())
        WidgetSharedStore.clear()
        XCTAssertNil(WidgetSharedStore.read())
    }
}
