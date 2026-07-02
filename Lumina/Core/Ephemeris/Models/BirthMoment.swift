import Foundation

/// Converts between picker-facing wall-clock values and the absolute
/// instants stored in `BirthData`, anchored at the birth place.
///
/// Why this exists: an `.hourAndMinute` `DatePicker` returns "today at
/// HH:mm in the device's time zone" and a `.date` picker returns midnight
/// of the shown day in the device's zone. Sending either verbatim to the
/// ephemeris computes a chart for the wrong instant — typically the day
/// the form was filled in, not the birthday, and in the wrong zone. Every
/// `BirthData` built from user input must go through `combine`.
enum BirthMoment {
    /// Gregorian calendar in the given zone; falls back to the device zone
    /// when the identifier is missing or unknown.
    static func calendar(_ timeZoneIdentifier: String?) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        if let timeZoneIdentifier, let zone = TimeZone(identifier: timeZoneIdentifier) {
            calendar.timeZone = zone
        }
        return calendar
    }

    /// Merges the calendar day shown by a `.date` picker with the wall-clock
    /// time shown by an `.hourAndMinute` picker into instants at the birth
    /// place. `birthDate` is anchored at *noon* in the birth zone so the
    /// calendar day survives re-interpretation in any other time zone.
    ///
    /// `deviceCalendar` is the calendar the pickers rendered in — always
    /// `.current` in the app; injectable so tests can pin both zones.
    static func combine(
        pickedDay: Date,
        pickedTime: Date?,
        timeZoneIdentifier: String?,
        deviceCalendar: Calendar = .current
    ) -> (birthDate: Date, birthTime: Date?) {
        var parts = deviceCalendar.dateComponents([.year, .month, .day], from: pickedDay)
        let birth = calendar(timeZoneIdentifier)

        var birthTime: Date?
        if let pickedTime {
            let wall = deviceCalendar.dateComponents([.hour, .minute], from: pickedTime)
            parts.hour = wall.hour
            parts.minute = wall.minute
            birthTime = birth.date(from: parts)
        }
        parts.hour = 12
        parts.minute = 0
        let birthDate = birth.date(from: parts) ?? pickedDay
        return (birthDate, birthTime)
    }

    /// Inverse of `combine`, for hydrating edit forms: re-anchors the stored
    /// birth-place wall clock in the device zone so pickers display the
    /// values the user originally chose regardless of where they are now.
    static func pickerValues(
        birthDate: Date,
        birthTime: Date?,
        timeZoneIdentifier: String?,
        deviceCalendar: Calendar = .current
    ) -> (day: Date, time: Date?) {
        let birth = calendar(timeZoneIdentifier)

        var dayParts = birth.dateComponents([.year, .month, .day], from: birthDate)
        dayParts.hour = 12
        let day = deviceCalendar.date(from: dayParts) ?? birthDate

        var time: Date?
        if let birthTime {
            let timeParts = birth.dateComponents([.year, .month, .day, .hour, .minute], from: birthTime)
            time = deviceCalendar.date(from: timeParts) ?? birthTime
        }
        return (day, time)
    }
}

extension BirthData {
    /// The one sanctioned way to build `BirthData` from date/time pickers.
    static func fromPickers(
        pickedDay: Date,
        pickedTime: Date?,
        placeName: String,
        latitude: Double,
        longitude: Double,
        timeZoneIdentifier: String,
        deviceCalendar: Calendar = .current
    ) -> BirthData {
        let (birthDate, birthTime) = BirthMoment.combine(
            pickedDay: pickedDay,
            pickedTime: pickedTime,
            timeZoneIdentifier: timeZoneIdentifier,
            deviceCalendar: deviceCalendar
        )
        return BirthData(
            birthDate: birthDate,
            birthTime: birthTime,
            placeName: placeName,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }
}
