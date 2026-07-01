@testable import Lumina
import XCTest

/// Tests for the iOS composite (midpoint) chart: wire decoding and the
/// grounded phrasing. Contract: `backend/src/routes/composite.ts`.
final class CompositeTests: XCTestCase {
    func testCompositeResultDecodesFromBackendJSON() throws {
        let json = """
        {
          "calculatedAt": "2026-06-05T00:00:00.000Z",
          "planets": [
            { "planet": "Sun", "longitude": 195.0, "latitude": 0.0, "isRetrograde": false },
            { "planet": "Moon", "longitude": 65.0, "latitude": 1.2, "isRetrograde": false }
          ],
          "aspects": [
            { "planet1": "Sun", "planet2": "Moon", "type": "trine", "exactAngle": 120, "orb": 1.4 }
          ]
        }
        """
        let result = try Self.wireDecoder().decode(CompositeResult.self, from: Data(json.utf8))
        XCTAssertEqual(result.planets.count, 2)
        XCTAssertEqual(result.aspects.count, 1)
        let sun = try XCTUnwrap(result.planets.first)
        XCTAssertEqual(sun.planet, "Sun")
        XCTAssertEqual(sun.longitude, 195, accuracy: 0.0001)
        XCTAssertFalse(sun.isRetrograde)
    }

    func testHeadlineNamesSunAndMoonSigns() {
        // Sun 195° → Libra, Moon 65° → Gemini.
        let composite = Self.make(sun: 195, moon: 65)
        XCTAssertEqual(
            CompositePhrasing.headline(for: composite),
            "As a pair, your relationship carries its Sun in Libra and its Moon in Gemini."
        )
    }

    func testHeadlineIsNilForEmptyComposite() {
        let empty = CompositeResult(calculatedAt: .now, planets: [], aspects: [])
        XCTAssertNil(CompositePhrasing.headline(for: empty))
    }

    func testCoreSignsReturnsSunMoonVenusInOrder() {
        let composite = Self.make(sun: 195, moon: 65, venus: 220)
        let core = CompositePhrasing.coreSigns(for: composite)
        XCTAssertEqual(core.map(\.planet), ["Sun", "Moon", "Venus"])
        XCTAssertEqual(core.map(\.sign), ["Libra", "Gemini", "Scorpio"])
    }

    func testCoreSignsSkipsMissingBodies() {
        let composite = Self.make(sun: 10)
        XCTAssertEqual(CompositePhrasing.coreSigns(for: composite).map(\.planet), ["Sun"])
    }

    func testTightestAspectReadsFromFirstAspect() {
        let composite = CompositeResult(
            calculatedAt: .now,
            planets: [],
            aspects: [
                NatalChart.Aspect(planet1: "Sun", planet2: "Venus", type: .sextile, exactAngle: 60, orb: 1.0),
                NatalChart.Aspect(planet1: "Mars", planet2: "Moon", type: .square, exactAngle: 90, orb: 4.0),
            ]
        )
        XCTAssertEqual(CompositePhrasing.tightestAspect(for: composite), "Sun sextile Venus")
    }

    // MARK: - Helpers

    private static func make(sun: Double, moon: Double? = nil, venus: Double? = nil) -> CompositeResult {
        var planets = [NatalChart.PlanetPosition(planet: "Sun", longitude: sun, latitude: 0, isRetrograde: false)]
        if let moon {
            planets.append(NatalChart.PlanetPosition(planet: "Moon", longitude: moon, latitude: 0, isRetrograde: false))
        }
        if let venus {
            planets.append(NatalChart.PlanetPosition(planet: "Venus", longitude: venus, latitude: 0, isRetrograde: false))
        }
        return CompositeResult(calculatedAt: .now, planets: planets, aspects: [])
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
