@testable import Lumina
import XCTest

/// Chart discovery progression: exploring a placement persists, celebrates
/// exactly once, and counts honestly against the placements a chart
/// actually has (no Ascendant without a birth time).
final class ChartDiscoveryTests: XCTestCase {
    /// Throwaway per-test suite so tests never touch (or see) real prefs.
    private func makeDefaults() -> UserDefaults? {
        UserDefaults(suiteName: "lumina.tests.discovery.\(UUID().uuidString)")
    }

    @MainActor
    func testMarkExploredReturnsTrueOnlyOnce() {
        guard let defaults = makeDefaults() else {
            XCTFail("could not create test UserDefaults suite")
            return
        }
        let discovery = ChartDiscovery(defaults: defaults)
        XCTAssertFalse(discovery.isExplored("Sun"))
        XCTAssertTrue(discovery.markExplored("Sun"), "first visit is a new discovery")
        XCTAssertFalse(discovery.markExplored("Sun"), "second visit is not a new discovery")
        XCTAssertTrue(discovery.isExplored("Sun"))
        XCTAssertFalse(discovery.isExplored("Moon"))
        XCTAssertEqual(discovery.exploredCount, 1)
    }

    @MainActor
    func testUnknownKeyIsNeverExplored() {
        guard let defaults = makeDefaults() else {
            XCTFail("could not create test UserDefaults suite")
            return
        }
        let discovery = ChartDiscovery(defaults: defaults)
        XCTAssertFalse(discovery.markExplored("Chiron"), "only real placement keys count")
        XCTAssertFalse(discovery.isExplored("Chiron"))
        XCTAssertEqual(discovery.exploredCount, 0)
    }

    @MainActor
    func testPersistenceRoundTrip() {
        guard let defaults = makeDefaults() else {
            XCTFail("could not create test UserDefaults suite")
            return
        }
        let first = ChartDiscovery(defaults: defaults)
        XCTAssertTrue(first.markExplored("Sun"))
        XCTAssertTrue(first.markExplored("Ascendant"))

        let second = ChartDiscovery(defaults: defaults)
        XCTAssertTrue(second.isExplored("Sun"))
        XCTAssertTrue(second.isExplored("Ascendant"))
        XCTAssertFalse(second.isExplored("Pluto"))
        XCTAssertFalse(second.markExplored("Sun"), "a reload must not re-celebrate old discoveries")
        XCTAssertEqual(second.exploredCount, 2)
    }

    @MainActor
    func testExploredCountOfSubset() {
        guard let defaults = makeDefaults() else {
            XCTFail("could not create test UserDefaults suite")
            return
        }
        let discovery = ChartDiscovery(defaults: defaults)
        XCTAssertTrue(discovery.markExplored("Sun"))
        XCTAssertTrue(discovery.markExplored("Moon"))
        XCTAssertTrue(discovery.markExplored("Ascendant"))

        // Unknown-birth-time charts count against ten keys, not eleven.
        let withoutAscendant = ChartDiscovery.placementKeys.filter { $0 != "Ascendant" }
        XCTAssertEqual(withoutAscendant.count, 10)
        XCTAssertEqual(discovery.exploredCount(of: withoutAscendant), 2)
        XCTAssertEqual(discovery.exploredCount(of: ChartDiscovery.placementKeys), 3)
        XCTAssertEqual(discovery.exploredCount(of: []), 0)
    }

    @MainActor
    func testCompletionCelebratedFlipsOnceAndPersists() {
        guard let defaults = makeDefaults() else {
            XCTFail("could not create test UserDefaults suite")
            return
        }
        let discovery = ChartDiscovery(defaults: defaults)
        XCTAssertFalse(discovery.completionCelebrated)
        XCTAssertTrue(discovery.celebrateCompletionIfNeeded(), "first completion celebrates")
        XCTAssertFalse(discovery.celebrateCompletionIfNeeded(), "never celebrates twice")
        XCTAssertTrue(discovery.completionCelebrated)

        let second = ChartDiscovery(defaults: defaults)
        XCTAssertTrue(second.completionCelebrated)
        XCTAssertFalse(second.celebrateCompletionIfNeeded(), "flag survives relaunch")
    }

    func testPlacementKeysAreCanonical() {
        XCTAssertEqual(ChartDiscovery.placementKeys.count, 11)
        XCTAssertEqual(ChartDiscovery.placementKeys, ChartGlyphs.planetOrder + ["Ascendant"])
    }
}
