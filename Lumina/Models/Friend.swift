import Foundation
import SwiftData

/// SwiftData model for one person in the user's people graph. Stored on
/// device only — friend data never syncs to the server unless the user
/// opts into discovery (Phase 10 of `ROADMAP.md`).
///
/// `birthTime` and birth-place coordinates are optional — friends imported
/// from Contacts often only carry a date.
@Model
final class Friend {
    enum Source: String, Codable, Sendable {
        case manual
        case contacts
        case qr
    }

    @Attribute(.unique) var id: UUID
    var name: String
    var birthDate: Date
    var birthTime: Date?
    var birthPlaceName: String?
    var birthLatitude: Double?
    var birthLongitude: Double?
    var birthTimeZoneIdentifier: String?
    var source: Source
    /// Cached compatibility score 0–100; recomputed when either chart
    /// changes. `nil` until first calculation runs.
    var compatibilityScore: Int?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        birthDate: Date,
        birthTime: Date? = nil,
        birthPlaceName: String? = nil,
        birthLatitude: Double? = nil,
        birthLongitude: Double? = nil,
        birthTimeZoneIdentifier: String? = nil,
        source: Source = .manual,
        compatibilityScore: Int? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.birthPlaceName = birthPlaceName
        self.birthLatitude = birthLatitude
        self.birthLongitude = birthLongitude
        self.birthTimeZoneIdentifier = birthTimeZoneIdentifier
        self.source = source
        self.compatibilityScore = compatibilityScore
        self.createdAt = createdAt
    }

    /// Returns a `BirthData` for the friend if enough fields are present,
    /// otherwise `nil`. The caller can fall back to a noon / current-time-zone
    /// chart for partial-data friends if it wants to compute a chart.
    func makeBirthData() -> BirthData? {
        guard let lat = birthLatitude,
              let lon = birthLongitude,
              let tz = birthTimeZoneIdentifier else {
            return nil
        }
        return BirthData(
            birthDate: birthDate,
            birthTime: birthTime,
            placeName: birthPlaceName ?? "",
            latitude: lat,
            longitude: lon,
            timeZoneIdentifier: tz
        )
    }
}
