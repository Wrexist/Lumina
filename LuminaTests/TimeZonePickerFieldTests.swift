@testable import Lumina
import XCTest

/// Filter contract for the shared `TimeZonePickerField` sheet: an empty or
/// whitespace-only query shows everything, matching is case-insensitive
/// substring, and the default source is `TimeZone.knownTimeZoneIdentifiers`.
final class TimeZonePickerFieldTests: XCTestCase {
    private let fixtures = [
        "Europe/Stockholm",
        "Europe/London",
        "America/New_York",
        "Asia/Tokyo",
    ]

    func testEmptyQueryReturnsEverything() {
        XCTAssertEqual(
            TimeZonePickerField.filteredIdentifiers(matching: "", in: fixtures),
            fixtures
        )
    }

    func testWhitespaceOnlyQueryReturnsEverything() {
        XCTAssertEqual(
            TimeZonePickerField.filteredIdentifiers(matching: "   ", in: fixtures),
            fixtures
        )
    }

    func testCaseInsensitiveSubstringMatch() {
        XCTAssertEqual(
            TimeZonePickerField.filteredIdentifiers(matching: "stockHOLM", in: fixtures),
            ["Europe/Stockholm"]
        )
        XCTAssertEqual(
            TimeZonePickerField.filteredIdentifiers(matching: "europe", in: fixtures),
            ["Europe/Stockholm", "Europe/London"]
        )
        XCTAssertEqual(
            TimeZonePickerField.filteredIdentifiers(matching: "new_y", in: fixtures),
            ["America/New_York"]
        )
    }

    func testQueryIsTrimmedBeforeMatching() {
        XCTAssertEqual(
            TimeZonePickerField.filteredIdentifiers(matching: "  Tokyo  ", in: fixtures),
            ["Asia/Tokyo"]
        )
    }

    func testNoMatchesReturnsEmpty() {
        XCTAssertTrue(
            TimeZonePickerField.filteredIdentifiers(matching: "Atlantis", in: fixtures).isEmpty
        )
    }

    func testDefaultsToKnownTimeZoneIdentifiers() {
        XCTAssertEqual(
            TimeZonePickerField.filteredIdentifiers(matching: ""),
            TimeZone.knownTimeZoneIdentifiers
        )
        XCTAssertTrue(
            TimeZonePickerField.filteredIdentifiers(matching: "Stockholm")
                .contains("Europe/Stockholm")
        )
    }
}
