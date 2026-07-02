@testable import Lumina
import XCTest

/// Regression tests for the picker → `BirthData` instant conversion.
/// The historical bug: `.hourAndMinute` pickers hand back "today at HH:mm
/// device-local", which was sent verbatim to the ephemeris — every timed
/// chart was computed for the day the form was filled in, not the birthday.
final class BirthMomentTests: XCTestCase {
    private func calendar(_ identifier: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: identifier))
        return calendar
    }

    /// A `Date` the way a picker would deliver it in the given zone.
    private func pickerDate(
        _ zone: String, year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0
    ) throws -> Date {
        try XCTUnwrap(calendar(zone).date(
            from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        ))
    }

    // MARK: - combine

    func testCombineBuildsBirthInstantInBirthZone() throws {
        let tokyo = try calendar("Asia/Tokyo")
        // User in Tokyo enters: born 1994-03-02 at 08:15 in New York.
        // The day comes from the date wheel; the time wheel's Date carries
        // "today" (2026-07-02) — exactly the poisoned value the bug shipped.
        let pickedDay = try pickerDate("Asia/Tokyo", year: 1994, month: 3, day: 2)
        let pickedTime = try pickerDate("Asia/Tokyo", year: 2026, month: 7, day: 2, hour: 8, minute: 15)

        let (birthDate, birthTime) = BirthMoment.combine(
            pickedDay: pickedDay,
            pickedTime: pickedTime,
            timeZoneIdentifier: "America/New_York",
            deviceCalendar: tokyo
        )

        // 08:15 EST on 1994-03-02 is 13:15 UTC.
        let expected = try calendar("America/New_York").date(
            from: DateComponents(year: 1994, month: 3, day: 2, hour: 8, minute: 15)
        )
        XCTAssertEqual(birthTime, expected)

        // birthDate is noon at the birth place: the calendar day survives
        // re-reading in the birth zone.
        let newYorkParts = try calendar("America/New_York")
            .dateComponents([.year, .month, .day], from: birthDate)
        XCTAssertEqual(newYorkParts.year, 1994)
        XCTAssertEqual(newYorkParts.month, 3)
        XCTAssertEqual(newYorkParts.day, 2)
    }

    func testCombineWithoutTimeAnchorsNoon() throws {
        let tokyo = try calendar("Asia/Tokyo")
        let pickedDay = try pickerDate("Asia/Tokyo", year: 1995, month: 6, day: 15)

        let (birthDate, birthTime) = BirthMoment.combine(
            pickedDay: pickedDay,
            pickedTime: nil,
            timeZoneIdentifier: "America/New_York",
            deviceCalendar: tokyo
        )

        XCTAssertNil(birthTime)
        // The shipped bug: Tokyo midnight = June 14 in New York → wrong
        // chart day. Noon anchoring keeps June 15.
        let parts = try calendar("America/New_York")
            .dateComponents([.year, .month, .day, .hour], from: birthDate)
        XCTAssertEqual(parts.day, 15)
        XCTAssertEqual(parts.hour, 12)
    }

    func testPickerValuesRoundTrip() throws {
        let tokyo = try calendar("Asia/Tokyo")
        let pickedDay = try pickerDate("Asia/Tokyo", year: 1988, month: 12, day: 31)
        let pickedTime = try pickerDate("Asia/Tokyo", year: 2026, month: 7, day: 2, hour: 23, minute: 45)

        let (birthDate, birthTime) = BirthMoment.combine(
            pickedDay: pickedDay,
            pickedTime: pickedTime,
            timeZoneIdentifier: "Europe/Stockholm",
            deviceCalendar: tokyo
        )
        let pickers = BirthMoment.pickerValues(
            birthDate: birthDate,
            birthTime: birthTime,
            timeZoneIdentifier: "Europe/Stockholm",
            deviceCalendar: tokyo
        )

        let dayParts = tokyo.dateComponents([.year, .month, .day], from: pickers.day)
        XCTAssertEqual(dayParts.year, 1988)
        XCTAssertEqual(dayParts.month, 12)
        XCTAssertEqual(dayParts.day, 31)
        let timeParts = tokyo.dateComponents([.hour, .minute], from: try XCTUnwrap(pickers.time))
        XCTAssertEqual(timeParts.hour, 23)
        XCTAssertEqual(timeParts.minute, 45)
    }

    func testUnknownZoneFallsBackToDevice() {
        let (birthDate, _) = BirthMoment.combine(
            pickedDay: Date(timeIntervalSince1970: 700_000_000),
            pickedTime: nil,
            timeZoneIdentifier: "Not/AZone"
        )
        let parts = Calendar.current.dateComponents([.hour], from: birthDate)
        XCTAssertEqual(parts.hour, 12)
    }

    // MARK: - SharedBirthData wire format

    func testSharedBirthDataEncodesCalendarComponents() throws {
        let tokyo = try calendar("Asia/Tokyo")
        let (anchoredDate, anchoredTime) = BirthMoment.combine(
            pickedDay: try pickerDate("Asia/Tokyo", year: 1996, month: 5, day: 21),
            pickedTime: nil,
            timeZoneIdentifier: "Asia/Tokyo",
            deviceCalendar: tokyo
        )
        let birthData = BirthData(
            birthDate: anchoredDate,
            birthTime: anchoredTime,
            placeName: "Tokyo, Japan",
            latitude: 35.68,
            longitude: 139.69,
            timeZoneIdentifier: "Asia/Tokyo"
        )
        let shared = SharedBirthData(from: birthData, name: "Yuki")
        XCTAssertEqual(shared.birthYear, 1996)
        XCTAssertEqual(shared.birthMonth, 5)
        XCTAssertEqual(shared.birthDay, 21)

        let data = try JSONEncoder.luminaShare.encode(shared)
        let decoded = try JSONDecoder.luminaShare.decode(SharedBirthData.self, from: data)
        XCTAssertEqual(decoded, shared)

        // The recipient — wherever they are — reads back May 21 in the
        // shared zone. Cusp charts (May 21 = Gemini) stay Gemini.
        let day = tokyo.dateComponents([.month, .day], from: decoded.birthDate)
        XCTAssertEqual(day.month, 5)
        XCTAssertEqual(day.day, 21)
    }

    func testSharedBirthDataDecodesLegacyInstantPayload() throws {
        // Payload shape shipped before component encoding: an ISO-8601
        // birthDate instant (Tokyo midnight = 15:00 UTC the previous day).
        let json = """
        {"birthDate":"1996-05-20T15:00:00Z","placeName":"Tokyo, Japan",
         "latitude":35.7,"longitude":139.7,"timeZoneIdentifier":"Asia/Tokyo"}
        """
        let decoded = try JSONDecoder.luminaShare.decode(
            SharedBirthData.self, from: Data(json.utf8)
        )
        XCTAssertEqual(decoded.birthYear, 1996)
        XCTAssertEqual(decoded.birthMonth, 5)
        XCTAssertEqual(decoded.birthDay, 21)
    }

    // MARK: - Zone-aware scoring

    func testCuspSunSignStableAcrossViewerZones() throws {
        // Born May 21 in Tokyo → Gemini. A viewer's calendar must not drag
        // the components back to May 20 (Taurus).
        let tokyo = try calendar("Asia/Tokyo")
        let newYork = try calendar("America/New_York")
        let birthDate = try XCTUnwrap(tokyo.date(
            from: DateComponents(year: 1996, month: 5, day: 21, hour: 12)
        ))
        let other = try XCTUnwrap(newYork.date(
            from: DateComponents(year: 1994, month: 3, day: 2, hour: 12)
        ))
        let summary = CompatibilityScorer.summary(
            for: birthDate, calendar: tokyo,
            other, calendar: newYork
        )
        XCTAssertEqual(summary, "Gemini · Pisces")
    }
}
