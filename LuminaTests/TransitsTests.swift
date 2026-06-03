@testable import Lumina
import XCTest

/// Tests for the transit models, wire-format decoding, and the honest
/// phrasing helper that replaces the Today tab's fabricated transit pool.
/// See `backend/src/routes/transits.ts` for the contract these mirror.
final class TransitsTests: XCTestCase {
    // MARK: - Wire-format decoding (mirrors backend POST /transits)

    func testTransitsResultDecodesFromBackendJSON() throws {
        let json = """
        {
          "calculatedAt": "2026-06-03T12:00:00.000Z",
          "transitAt": "2026-06-03T12:00:00.000Z",
          "transitingPlanets": [
            { "planet": "Sun", "longitude": 72.93, "latitude": 0.0, "isRetrograde": false },
            { "planet": "Mercury", "longitude": 64.1, "latitude": 1.2, "isRetrograde": true }
          ],
          "transits": [
            { "transiting": "Pluto", "natal": "Mercury", "type": "trine", "exactAngle": 120, "orb": 0.39, "applying": false },
            { "transiting": "Venus", "natal": "Venus", "type": "sextile", "exactAngle": 60, "orb": 0.46, "applying": true }
          ]
        }
        """
        let result = try Self.wireDecoder().decode(TransitsResult.self, from: Data(json.utf8))
        XCTAssertEqual(result.transitingPlanets.count, 2)
        XCTAssertEqual(result.transitingPlanets.first?.planet, "Sun")
        XCTAssertTrue(result.transitingPlanets[1].isRetrograde)
        XCTAssertEqual(result.transits.count, 2)

        let trine = try XCTUnwrap(result.transits.first)
        XCTAssertEqual(trine.transiting, "Pluto")
        XCTAssertEqual(trine.natal, "Mercury")
        XCTAssertEqual(trine.type, .trine)
        XCTAssertEqual(trine.orb, 0.39, accuracy: 0.0001)
        XCTAssertFalse(trine.applying)
    }

    func testTransitReadingIDIsStableAndUnique() {
        let tightTrine = TransitReading(
            transiting: "Mars", natal: "Venus", type: .trine, exactAngle: 120, orb: 1, applying: true
        )
        let looseTrine = TransitReading(
            transiting: "Mars", natal: "Venus", type: .trine, exactAngle: 120, orb: 2, applying: false
        )
        let otherTarget = TransitReading(
            transiting: "Mars", natal: "Sun", type: .trine, exactAngle: 120, orb: 1, applying: true
        )
        XCTAssertEqual(tightTrine.id, looseTrine.id, "id ignores orb/applying — same contact")
        XCTAssertNotEqual(tightTrine.id, otherTarget.id, "different natal target → different id")
        XCTAssertEqual(tightTrine.id, "Mars-trine-Venus")
    }

    // MARK: - Phrasing

    func testPhrasingReadsHonestlyForEachAspect() {
        XCTAssertEqual(
            TransitPhrasing.sentence(for: reading(.trine, applying: true)),
            "Mars trine your Venus, building"
        )
        XCTAssertEqual(
            TransitPhrasing.sentence(for: reading(.square, applying: false)),
            "Mars square your Venus, easing"
        )
        XCTAssertEqual(TransitPhrasing.aspectWord(.conjunction), "conjunct")
        XCTAssertEqual(TransitPhrasing.aspectWord(.opposition), "opposite")
        XCTAssertEqual(TransitPhrasing.aspectWord(.sextile), "sextile")
    }

    func testSolarReturnPhrasing() {
        let sunReturn = TransitReading(
            transiting: "Sun", natal: "Sun", type: .conjunction, exactAngle: 0, orb: 0.01, applying: true
        )
        XCTAssertEqual(TransitPhrasing.sentence(for: sunReturn), "Sun conjunct your Sun, building")
    }

    // MARK: - Helpers

    private func reading(_ type: AspectType, applying: Bool) -> TransitReading {
        TransitReading(transiting: "Mars", natal: "Venus", type: type, exactAngle: 0, orb: 1, applying: applying)
    }

    /// Mirrors `EphemerisService.chartDecoder`'s ISO-8601 date strategy so the
    /// test exercises the exact wire format the backend emits (it always
    /// includes fractional seconds via `Date.toISOString()`).
    private static func wireDecoder() -> JSONDecoder {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let withoutFraction = ISO8601DateFormatter()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = withFraction.date(from: raw) { return date }
            if let date = withoutFraction.date(from: raw) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "bad date \(raw)")
        }
        return decoder
    }
}
