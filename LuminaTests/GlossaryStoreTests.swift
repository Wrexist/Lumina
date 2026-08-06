@testable import Lumina
import XCTest

/// Tests for `GlossaryStore` lookup and decoding: alias resolution, duplicate
/// keys in the JSON, and entries that omit the optional `aliases` array.
final class GlossaryStoreTests: XCTestCase {
    /// Three entries: one with aliases, one with no "aliases" key at all
    /// (must still decode), and a duplicate key (must not crash the load).
    private static let fixtureJSON = Data("""
    [
      {
        "key": "rising sign",
        "displayName": "Rising sign",
        "category": "astrology",
        "summary": "The sign on the eastern horizon at birth.",
        "body": "Also called the Ascendant.",
        "aliases": ["ascendant", "asc"]
      },
      {
        "key": "midheaven",
        "displayName": "Midheaven",
        "category": "astrology",
        "summary": "The highest point of the sky at birth.",
        "body": "Often abbreviated MC."
      },
      {
        "key": "midheaven",
        "displayName": "Midheaven (duplicate)",
        "category": "astrology",
        "summary": "A duplicate key is a content bug.",
        "body": "The store keeps the first entry rather than trapping."
      }
    ]
    """.utf8)

    @MainActor
    func testAliasesResolveToTheirCanonicalEntry() throws {
        let store = GlossaryStore()
        try store.load(data: Self.fixtureJSON)
        XCTAssertEqual(store.entry(for: "Ascendant")?.key, "rising sign")
        XCTAssertEqual(store.entry(for: "ASC")?.key, "rising sign")
        XCTAssertEqual(store.entry(for: "Rising Sign")?.key, "rising sign")
        XCTAssertNil(store.entry(for: "unknown term"))
    }

    @MainActor
    func testAliasesDoNotInflateTheBrowsableEntryList() throws {
        let store = GlossaryStore()
        try store.load(data: Self.fixtureJSON)
        // `entries` backs the Glossary screen's list — aliases belong in the
        // lookup only, or every alias would render as an extra row.
        XCTAssertEqual(store.entries.count, 2)
        XCTAssertNil(store.entries["ascendant"])
    }

    @MainActor
    func testDuplicateKeyKeepsFirstEntryInsteadOfCrashing() throws {
        let store = GlossaryStore()
        try store.load(data: Self.fixtureJSON)
        XCTAssertEqual(store.entry(for: "Midheaven")?.displayName, "Midheaven")
    }

    /// Terms for a feature the build can't reach are decoded but not served —
    /// a definition of "heart line" in an app with no palm surface advertises
    /// something that isn't there. See `GlossaryStore.shipped(_:)`.
    @MainActor
    func testEntriesForUnreachableFeaturesAreNotServed() throws {
        let json = Data("""
        [
          {
            "key": "heart line",
            "displayName": "Heart line",
            "category": "palmistry",
            "summary": "The horizontal line near the top of the palm.",
            "body": "Read for emotional style."
          },
          {
            "key": "midheaven",
            "displayName": "Midheaven",
            "category": "astrology",
            "summary": "The highest point of the sky at birth.",
            "body": "Often abbreviated MC."
          }
        ]
        """.utf8)
        let store = GlossaryStore()
        try store.load(data: json)

        XCTAssertNotNil(store.entry(for: "midheaven"))
        if LuminaTab.visible.contains(.palm) {
            XCTAssertNotNil(store.entry(for: "heart line"), "palm ships — its terms belong")
        } else {
            XCTAssertNil(store.entry(for: "heart line"), "palm is unreachable — its terms must not show")
            XCTAssertEqual(store.entries.count, 1)
        }
    }

    func testEntryWithoutAliasesKeyStillDecodes() throws {
        let raw = try JSONDecoder().decode([GlossaryEntry].self, from: Self.fixtureJSON)
        XCTAssertEqual(raw.count, 3)
        XCTAssertEqual(raw[0].aliases, ["ascendant", "asc"])
        XCTAssertEqual(raw[1].aliases, [])
    }
}
