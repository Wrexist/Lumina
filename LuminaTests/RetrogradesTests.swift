@testable import Lumina
import XCTest

/// Tests for the iOS retrogrades model decoding and the calm phrasing.
/// Contract: `backend/src/routes/retrogrades.ts`.
final class RetrogradesTests: XCTestCase {
    func testRetrogradesResultDecodesFromBackendJSON() throws {
        let json = """
        {
          "calculatedAt": "2026-06-05T00:00:00.000Z",
          "at": "2026-06-05T00:00:00.000Z",
          "planets": [
            { "planet": "Mercury", "isRetrograde": true, "nextStationAt": "2026-06-14T00:00:00.000Z", "nextStationDirection": "direct" },
            { "planet": "Venus", "isRetrograde": false, "nextStationAt": null, "nextStationDirection": null }
          ]
        }
        """
        let result = try Self.wireDecoder().decode(RetrogradesResult.self, from: Data(json.utf8))
        XCTAssertEqual(result.planets.count, 2)
        let mercury = try XCTUnwrap(result.planets.first)
        XCTAssertTrue(mercury.isRetrograde)
        XCTAssertEqual(mercury.nextStationDirection, .direct)
        let venus = try XCTUnwrap(result.planets.last)
        XCTAssertFalse(venus.isRetrograde)
        XCTAssertNil(venus.nextStationAt)
        XCTAssertNil(venus.nextStationDirection)
    }

    func testSummaryHandlesNoneSingleAndMany() {
        XCTAssertEqual(
            RetrogradePhrasing.summary(for: Self.make(retrograde: [])),
            "No planets are retrograde right now — a clear, direct sky."
        )
        XCTAssertEqual(
            RetrogradePhrasing.summary(for: Self.make(retrograde: ["Mercury"])),
            "Mercury is retrograde right now."
        )
        XCTAssertEqual(
            RetrogradePhrasing.summary(for: Self.make(retrograde: ["Mercury", "Saturn", "Pluto"])),
            "Mercury, Saturn and Pluto are retrograde right now."
        )
    }

    func testStationLineUsesTheRightVerbAndIsNilWithoutAStation() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        let direct = RetrogradeState(planet: "Mercury", isRetrograde: true, nextStationAt: date, nextStationDirection: .direct)
        XCTAssertEqual(
            RetrogradePhrasing.stationLine(for: direct, formatter: formatter),
            "Mercury turns direct \(formatter.string(from: date))."
        )

        let retro = RetrogradeState(planet: "Mars", isRetrograde: false, nextStationAt: date, nextStationDirection: .retrograde)
        XCTAssertEqual(
            RetrogradePhrasing.stationLine(for: retro, formatter: formatter),
            "Mars stations retrograde \(formatter.string(from: date))."
        )

        let none = RetrogradeState(planet: "Pluto", isRetrograde: false, nextStationAt: nil, nextStationDirection: nil)
        XCTAssertNil(RetrogradePhrasing.stationLine(for: none, formatter: formatter))
    }

    // MARK: - Helpers

    private static func make(retrograde: [String]) -> RetrogradesResult {
        let names = ["Mercury", "Venus", "Mars", "Jupiter", "Saturn", "Pluto"]
        let planets = names.map { name in
            RetrogradeState(
                planet: name,
                isRetrograde: retrograde.contains(name),
                nextStationAt: nil,
                nextStationDirection: nil
            )
        }
        return RetrogradesResult(calculatedAt: .now, at: .now, planets: planets)
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
