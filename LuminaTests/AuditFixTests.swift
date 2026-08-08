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

    // MARK: - Hostile share payloads
    //
    // A share payload is fully untrusted: anyone can build a `lumina://share/…`
    // URL or print a QR code. These pin that every field is range-checked at
    // decode, so a bad payload fails cleanly instead of producing a
    // confident-looking chart from nonsense.

    private func sharePayload(_ overrides: [String: Any]) throws -> Data {
        var object: [String: Any] = [
            "birthYear": 1990,
            "birthMonth": 6,
            "birthDay": 15,
            "placeName": "Stockholm",
            "latitude": 59.3,
            "longitude": 18.1,
            "timeZoneIdentifier": "Europe/Stockholm",
        ]
        for (key, value) in overrides { object[key] = value }
        return try JSONSerialization.data(withJSONObject: object)
    }

    func testSharePayloadRejectsOutOfRangeFields() throws {
        let hostile: [String: Any] = [
            "birthMonth": 77,
            "birthDay": 99,
            "birthYear": 99_999,
            "latitude": 1_000.0,
            "longitude": -1_000.0,
            "timeZoneIdentifier": "Not/AZone",
        ]
        for (key, value) in hostile {
            let data = try sharePayload([key: value])
            XCTAssertThrowsError(
                try JSONDecoder.luminaShare.decode(SharedBirthData.self, from: data),
                "\(key) = \(value) must be rejected"
            )
        }
    }

    func testSharePayloadAcceptsAPlausibleOne() throws {
        let decoded = try JSONDecoder.luminaShare.decode(
            SharedBirthData.self,
            from: try sharePayload([:])
        )
        XCTAssertEqual(decoded.birthYear, 1990)
        XCTAssertEqual(decoded.birthMonth, 6)
        XCTAssertEqual(decoded.birthDay, 15)
    }

    func testSharePayloadTruncatesUnboundedText() throws {
        let data = try sharePayload([
            "name": String(repeating: "a", count: 5_000),
            "placeName": String(repeating: "b", count: 5_000),
        ])
        let decoded = try JSONDecoder.luminaShare.decode(SharedBirthData.self, from: data)
        XCTAssertLessThanOrEqual(decoded.name?.count ?? 0, 60)
        XCTAssertLessThanOrEqual(decoded.placeName.count, 200)
    }

    func testOversizedSharePayloadIsRefusedBeforeDecoding() {
        // Valid base64url, just implausibly large for a share payload.
        let huge = String(repeating: "A", count: Data.maxSharePayloadBytes + 4)
        XCTAssertNil(Data(base64URLEncoded: huge))
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

    // MARK: - Deep-link parsing (universal links parse identically)

    func testUniversalLinkMalformedInputsParseSafely() {
        // Same malformed shapes as above, but via the `https://lumina.app/...`
        // universal link — must fall back exactly the same way as `lumina://`.
        XCTAssertEqual(LuminaDeepLink.from(url: link("https://lumina.app/chart/planet")), .chart(planet: nil))
        XCTAssertEqual(LuminaDeepLink.from(url: link("https://lumina.app/people/not-a-uuid")), .people(friendID: nil))
        XCTAssertEqual(LuminaDeepLink.from(url: link("https://lumina.app/share/")), .today)
    }

    func testShareUniversalLinkMatchesCustomSchemeShape() {
        // The QR share flow (`ShareQRView`) emits `https://lumina.app/share/...`
        // — confirm it decodes to the identical case as the legacy
        // `lumina://share/...` shape `AcceptShareView` has always consumed.
        let payload = "abcDEF123"
        XCTAssertEqual(
            LuminaDeepLink.from(url: link("https://lumina.app/share/\(payload)")),
            LuminaDeepLink.from(url: link("lumina://share/\(payload)"))
        )
    }

    // MARK: - Helpers

    private func link(_ string: String) -> URL {
        URL(string: string) ?? URL(fileURLWithPath: "/")
    }
}
