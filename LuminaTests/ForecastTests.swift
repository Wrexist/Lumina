@testable import Lumina
import XCTest

/// Tests for the iOS forecast models, wire decoding, and phrasing. Contract:
/// `backend/src/routes/forecast.ts`.
final class ForecastTests: XCTestCase {
    func testForecastResultDecodesFromBackendJSON() throws {
        let json = """
        {
          "calculatedAt": "2026-06-05T00:00:00.000Z",
          "from": "2026-06-05T00:00:00.000Z",
          "days": 30,
          "events": [
            { "transiting": "Mars", "natal": "Venus", "type": "trine", "exactAngle": 120, "exactAt": "2026-06-12T08:30:00.000Z" },
            { "transiting": "Saturn", "natal": "Sun", "type": "square", "exactAngle": 90, "exactAt": "2026-06-20T00:00:00.000Z" }
          ]
        }
        """
        let result = try Self.wireDecoder().decode(ForecastResult.self, from: Data(json.utf8))
        XCTAssertEqual(result.days, 30)
        XCTAssertEqual(result.events.count, 2)
        let first = try XCTUnwrap(result.events.first)
        XCTAssertEqual(first.transiting, "Mars")
        XCTAssertEqual(first.natal, "Venus")
        XCTAssertEqual(first.type, .trine)
        XCTAssertEqual(first.id, "Mars-trine-Venus-\(first.exactAt.timeIntervalSince1970)")
    }

    func testPhrasingReadsAsExpected() {
        let event = ForecastEvent(
            transiting: "Saturn", natal: "Sun", type: .square, exactAngle: 90, exactAt: .now
        )
        XCTAssertEqual(ForecastPhrasing.line(for: event), "Saturn square your Sun")
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
