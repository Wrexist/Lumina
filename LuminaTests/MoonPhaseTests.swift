@testable import Lumina
import XCTest

/// Tests for the iOS Moon-phase model wire decoding and the pure presentation
/// helpers. Contract: `backend/src/routes/moon.ts`.
final class MoonPhaseTests: XCTestCase {
    func testMoonPhaseResultDecodesFromBackendJSON() throws {
        let json = """
        {
          "calculatedAt": "2026-06-05T00:00:00.000Z",
          "at": "2026-06-05T00:00:00.000Z",
          "angle": 236.3,
          "phase": "Waning Gibbous",
          "illumination": 0.778,
          "nextNewMoon": "2026-06-14T00:00:00.000Z",
          "nextFullMoon": "2026-06-29T23:57:17.744Z"
        }
        """
        let result = try Self.wireDecoder().decode(MoonPhaseResult.self, from: Data(json.utf8))
        XCTAssertEqual(result.phase, "Waning Gibbous")
        XCTAssertEqual(result.angle, 236.3, accuracy: 0.001)
        XCTAssertEqual(result.illumination, 0.778, accuracy: 0.001)
        XCTAssertGreaterThan(result.nextFullMoon, result.nextNewMoon)
    }

    func testSymbolMapsEveryPhaseName() {
        XCTAssertEqual(MoonPhasePresentation.symbol(for: "New Moon"), "moonphase.new.moon")
        XCTAssertEqual(MoonPhasePresentation.symbol(for: "First Quarter"), "moonphase.first.quarter")
        XCTAssertEqual(MoonPhasePresentation.symbol(for: "Full Moon"), "moonphase.full.moon")
        XCTAssertEqual(MoonPhasePresentation.symbol(for: "Waning Gibbous"), "moonphase.waning.gibbous")
    }

    func testSymbolFallsBackForUnknownPhase() {
        XCTAssertEqual(MoonPhasePresentation.symbol(for: "Blood Moon"), "moon")
    }

    func testIlluminationTextRoundsToWholePercent() {
        XCTAssertEqual(MoonPhasePresentation.illuminationText(0.778), "78% illuminated")
        XCTAssertEqual(MoonPhasePresentation.illuminationText(0), "0% illuminated")
        XCTAssertEqual(MoonPhasePresentation.illuminationText(1), "100% illuminated")
    }

    func testNextEventPicksTheNearerMilestone() {
        // Anchored at local noon so the +1 hour "today" case never crosses
        // midnight, whatever time zone the host runs in — the helper counts
        // local calendar days.
        let now = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now) ?? .now
        let inDays: (Int) -> Date = { now.addingTimeInterval(Double($0) * 86_400) }

        // Full sooner than new.
        XCTAssertEqual(
            MoonPhasePresentation.nextEvent(nextNew: inDays(20), nextFull: inDays(6), now: now),
            "Full moon in 6 days"
        )
        // New sooner than full.
        XCTAssertEqual(
            MoonPhasePresentation.nextEvent(nextNew: inDays(2), nextFull: inDays(15), now: now),
            "New moon in 2 days"
        )
        // Tomorrow / today phrasing.
        XCTAssertEqual(
            MoonPhasePresentation.nextEvent(nextNew: inDays(1), nextFull: inDays(15), now: now),
            "New moon tomorrow"
        )
        XCTAssertEqual(
            MoonPhasePresentation.nextEvent(nextNew: now.addingTimeInterval(3_600), nextFull: inDays(15), now: now),
            "New moon today"
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
