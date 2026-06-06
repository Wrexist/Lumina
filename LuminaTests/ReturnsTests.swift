@testable import Lumina
import XCTest

/// Tests for the iOS returns model decoding and the calm life-stage phrasing.
/// Contract: `backend/src/routes/returns.ts`.
final class ReturnsTests: XCTestCase {
    func testReturnsResultDecodesFromBackendJSON() throws {
        let json = """
        {
          "calculatedAt": "2026-06-05T00:00:00.000Z",
          "from": "2026-06-05T00:00:00.000Z",
          "events": [
            { "planet": "Jupiter", "returnNumber": 3, "exactAt": "2037-08-01T00:00:00.000Z", "natalLongitude": 95.2 },
            { "planet": "Saturn", "returnNumber": 2, "exactAt": "2049-04-01T00:00:00.000Z", "natalLongitude": 280.4 }
          ]
        }
        """
        let result = try Self.wireDecoder().decode(ReturnsResult.self, from: Data(json.utf8))
        XCTAssertEqual(result.events.count, 2)
        let saturn = try XCTUnwrap(result.events.first(where: { $0.planet == "Saturn" }))
        XCTAssertEqual(saturn.returnNumber, 2)
        XCTAssertEqual(saturn.id, "Saturn-2")
    }

    func testLineUsesOrdinalAndDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let event = ReturnEvent(
            planet: "Saturn",
            returnNumber: 2,
            exactAt: Date(timeIntervalSince1970: 2_500_000_000),
            natalLongitude: 280
        )
        XCTAssertEqual(
            ReturnPhrasing.line(for: event, formatter: formatter),
            "Your second Saturn return arrives \(formatter.string(from: event.exactAt))."
        )
    }

    func testImminentKeepsOnlyReturnsWithinTheWindowSoonestFirst() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let inDays: (Int) -> Date = { now.addingTimeInterval(Double($0) * 86_400) }
        let events = [
            ReturnEvent(planet: "Saturn", returnNumber: 2, exactAt: inDays(300), natalLongitude: 280),
            ReturnEvent(planet: "Jupiter", returnNumber: 4, exactAt: inDays(40), natalLongitude: 95),
            ReturnEvent(planet: "Uranus", returnNumber: 1, exactAt: inDays(900), natalLongitude: 10),
            ReturnEvent(planet: "Mars", returnNumber: 9, exactAt: inDays(-10), natalLongitude: 200),
        ]
        let imminent = ReturnPhrasing.imminent(events, within: 365, from: now)
        XCTAssertEqual(imminent.map(\.planet), ["Jupiter", "Saturn"])
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
