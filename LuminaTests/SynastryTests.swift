@testable import Lumina
import XCTest

/// Tests for the iOS synastry models, wire decoding, request encoding, and
/// the plain-English phrasing. Contract lives in `backend/src/routes/synastry.ts`.
final class SynastryTests: XCTestCase {
    func testSynastryResultDecodesFromBackendJSON() throws {
        let json = """
        {
          "calculatedAt": "2026-06-03T12:00:00.000Z",
          "aspects": [
            { "planetA": "Venus", "planetB": "Mars", "type": "conjunction", "exactAngle": 0, "orb": 1.12 },
            { "planetA": "Sun", "planetB": "Moon", "type": "trine", "exactAngle": 120, "orb": 1.6 }
          ]
        }
        """
        let result = try Self.wireDecoder().decode(SynastryResult.self, from: Data(json.utf8))
        XCTAssertEqual(result.aspects.count, 2)
        let first = try XCTUnwrap(result.aspects.first)
        XCTAssertEqual(first.planetA, "Venus")
        XCTAssertEqual(first.planetB, "Mars")
        XCTAssertEqual(first.type, .conjunction)
        XCTAssertEqual(first.orb, 1.12, accuracy: 0.0001)
        XCTAssertEqual(first.id, "Venus-conjunction-Mars")
    }

    func testPhrasingReadsAsPlainEnglish() {
        let conjunction = SynastryAspect(
            planetA: "Venus", planetB: "Mars", type: .conjunction, exactAngle: 0, orb: 1
        )
        XCTAssertEqual(SynastryPhrasing.sentence(for: conjunction), "Your Venus conjunct their Mars")
        let trine = SynastryAspect(
            planetA: "Sun", planetB: "Moon", type: .trine, exactAngle: 120, orb: 1
        )
        XCTAssertEqual(SynastryPhrasing.sentence(for: trine), "Your Sun trine their Moon")
    }

    func testSynastryPersonOmitsNilFields() throws {
        // The backend treats birthTime/timeZoneIdentifier as optional (not
        // nullable), so a nil must be *omitted* — not encoded as JSON null.
        let person = SynastryPerson(
            birthDate: Date(timeIntervalSince1970: 0), birthTime: nil, timeZoneIdentifier: nil
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let json = try XCTUnwrap(String(data: encoder.encode(person), encoding: .utf8))
        XCTAssertTrue(json.contains("birthDate"))
        XCTAssertFalse(json.contains("birthTime"), "nil birthTime must be omitted, not null")
        XCTAssertFalse(json.contains("timeZoneIdentifier"), "nil zone must be omitted, not null")
    }

    private static func wireDecoder() -> JSONDecoder {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = withFraction.date(from: raw) { return date }
            if let date = ISO8601DateFormatter().date(from: raw) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "bad date \(raw)")
        }
        return decoder
    }
}
