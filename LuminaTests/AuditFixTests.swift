@testable import Lumina
import XCTest

/// Regression tests for the 2026-06 audit remediation pass. Each guards a
/// specific bug that was fixed — see `docs/AUDIT-2026-06-03.md`.
final class AuditFixTests: XCTestCase {
    // MARK: - Share QR round-trip (SharedBirthData / base64url)

    func testSharedBirthDataBase64URLRoundTrips() throws {
        let birth = BirthData(
            birthDate: Date(timeIntervalSince1970: 0),
            birthTime: nil,
            placeName: "Stockholm, Sweden",
            latitude: 59.3293,
            longitude: 18.0686,
            timeZoneIdentifier: "Europe/Stockholm"
        )
        let payload = try JSONEncoder.luminaShare
            .encode(SharedBirthData(from: birth, name: "Sam"))
            .base64URLEncodedString()
        // base64url must not contain characters that break a URL path component.
        XCTAssertFalse(payload.contains("/"))
        XCTAssertFalse(payload.contains("+"))
        XCTAssertFalse(payload.contains("="))

        let data = try XCTUnwrap(Data(base64URLEncoded: payload))
        let decoded = try JSONDecoder.luminaShare.decode(SharedBirthData.self, from: data)
        XCTAssertEqual(decoded.name, "Sam")
        XCTAssertEqual(decoded.placeName, "Stockholm, Sweden")
        // Coordinates are coarsened to ~city level (1 decimal place).
        XCTAssertEqual(decoded.latitude, 59.3, accuracy: 0.0001)
        XCTAssertEqual(decoded.longitude, 18.1, accuracy: 0.0001)
    }

    func testSharedBirthDataNeverSharesExactTime() {
        let birth = BirthData(
            birthDate: .now, birthTime: .now, placeName: "X",
            latitude: 1, longitude: 2, timeZoneIdentifier: "UTC"
        )
        XCTAssertNil(SharedBirthData(from: birth).toBirthData().birthTime)
    }

    func testMalformedSharePayloadDoesNotCrash() {
        let decoded = Data(base64URLEncoded: "@@@not-base64@@@")
            .flatMap { try? JSONDecoder.luminaShare.decode(SharedBirthData.self, from: $0) }
        XCTAssertNil(decoded)
    }

    // MARK: - CompatibilityScorer stability (FNV-1a, not randomized hashValue)

    func testStableHashMatchesAFixedValue() {
        // FNV-1a is deterministic across processes; String.hashValue is seeded
        // per run, which silently drifted the persisted score on every launch.
        XCTAssertEqual(CompatibilityScorer.stableHash("Aries-Leo"), 11_545_899_016_306_400_076)
    }

    // MARK: - Ordinal house grammar (the "1th house" bug)

    func testHouseOrdinalGrammar() {
        XCTAssertEqual(ChartGlyphs.ordinal(1), "1st")
        XCTAssertEqual(ChartGlyphs.ordinal(2), "2nd")
        XCTAssertEqual(ChartGlyphs.ordinal(3), "3rd")
        XCTAssertEqual(ChartGlyphs.ordinal(4), "4th")
        XCTAssertEqual(ChartGlyphs.ordinal(11), "11th")
        XCTAssertEqual(ChartGlyphs.ordinal(12), "12th")
    }

    // MARK: - Deep-link parsing (malformed inputs)

    func testMalformedDeepLinksParseSafely() {
        XCTAssertEqual(LuminaDeepLink.from(url: link("lumina://chart/planet")), .chart(planet: nil))
        XCTAssertEqual(LuminaDeepLink.from(url: link("lumina://people/not-a-uuid")), .people(friendID: nil))
        XCTAssertEqual(LuminaDeepLink.from(url: link("lumina://share/")), .today)
        XCTAssertNil(LuminaDeepLink.from(url: link("https://example.com/chart")))
    }

    // MARK: - Helpers

    private func link(_ string: String) -> URL {
        URL(string: string) ?? URL(fileURLWithPath: "/")
    }
}
