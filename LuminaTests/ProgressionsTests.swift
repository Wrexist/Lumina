@testable import Lumina
import XCTest

/// Tests for the iOS progressed-chart model decoding and the grounded chapter
/// phrasing. Contract: `backend/src/routes/progressions.ts`.
final class ProgressionsTests: XCTestCase {
    func testProgressionsResultDecodesFromBackendJSON() throws {
        let json = """
        {
          "calculatedAt": "2026-06-05T00:00:00.000Z",
          "on": "2026-06-05T00:00:00.000Z",
          "progressedAt": "1990-07-15T14:30:00.000Z",
          "planets": [
            { "planet": "Sun", "longitude": 130.0, "latitude": 0.0, "isRetrograde": false },
            { "planet": "Moon", "longitude": 215.0, "latitude": 0.0, "isRetrograde": false }
          ]
        }
        """
        let result = try Self.wireDecoder().decode(ProgressionsResult.self, from: Data(json.utf8))
        XCTAssertEqual(result.planets.count, 2)
        let moon = try XCTUnwrap(result.planets.first(where: { $0.planet == "Moon" }))
        XCTAssertEqual(moon.longitude, 215, accuracy: 0.0001)
    }

    func testMoonLineNamesTheProgressedMoonSign() throws {
        // Moon 215° → Scorpio.
        let result = Self.make(sun: 130, moon: 215)
        let line = try XCTUnwrap(ProgressedChapter.moonLine(for: result))
        XCTAssertTrue(line.contains("Scorpio"))
    }

    func testSunLineNamesTheProgressedSunSign() throws {
        // Sun 130° → Leo.
        let result = Self.make(sun: 130, moon: 215)
        XCTAssertEqual(ProgressedChapter.sunLine(for: result), "Progressed Sun in Leo")
    }

    func testMoonLineIsNilWithoutAProgressedMoon() {
        let result = ProgressionsResult(calculatedAt: .now, on: .now, progressedAt: .now, planets: [])
        XCTAssertNil(ProgressedChapter.moonLine(for: result))
    }

    // MARK: - Helpers

    private static func make(sun: Double, moon: Double) -> ProgressionsResult {
        ProgressionsResult(
            calculatedAt: .now,
            on: .now,
            progressedAt: .now,
            planets: [
                NatalChart.PlanetPosition(planet: "Sun", longitude: sun, latitude: 0, isRetrograde: false),
                NatalChart.PlanetPosition(planet: "Moon", longitude: moon, latitude: 0, isRetrograde: false),
            ]
        )
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
