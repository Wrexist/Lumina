import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Everything Lumina holds about you, as one JSON file.
///
/// The privacy dashboard promised this ("Full data export is coming before
/// public launch") and nothing implemented it. Beyond the broken promise,
/// portability is a real obligation under GDPR Art. 20 and CCPA, and the
/// account-deletion flow already proves we can enumerate every store — export
/// reads the same set, so the two can't drift apart.
///
/// Deliberately plain JSON rather than a zip or a proprietary shape: it opens
/// in any text editor, and a person exercising a data-access right should be
/// able to read what comes back without our app.
///
/// `Encodable`, not `Codable` — nothing reads this back, and synthesising a
/// decoder over the two constant fields below would warn that immutable
/// properties with initial values can't be decoded (a warning this target
/// treats as an error).
struct LuminaDataExport: Encodable, Sendable {
    struct Journal: Encodable, Sendable {
        let id: UUID
        let date: Date
        let prompt: String
        let body: String
        let wordCount: Int
        let createdAt: Date
        let updatedAt: Date

        init(_ entry: JournalEntry) {
            id = entry.id
            date = entry.date
            prompt = entry.prompt
            body = entry.body
            wordCount = entry.wordCount
            createdAt = entry.createdAt
            updatedAt = entry.updatedAt
        }
    }

    struct Person: Encodable, Sendable {
        let id: UUID
        let name: String
        let birthDate: Date
        let birthTime: Date?
        let birthPlaceName: String?
        let birthLatitude: Double?
        let birthLongitude: Double?
        let birthTimeZoneIdentifier: String?
        let compatibilityScore: Int?
        let addedAt: Date

        init(_ friend: Friend) {
            id = friend.id
            name = friend.name
            birthDate = friend.birthDate
            birthTime = friend.birthTime
            birthPlaceName = friend.birthPlaceName
            birthLatitude = friend.birthLatitude
            birthLongitude = friend.birthLongitude
            birthTimeZoneIdentifier = friend.birthTimeZoneIdentifier
            compatibilityScore = friend.compatibilityScore
            addedAt = friend.createdAt
        }
    }

    struct Milestone: Encodable, Sendable {
        let name: String
        let unlockedAt: Date
    }

    /// Schema version, so a future importer can tell what it's reading.
    let formatVersion = 1
    let exportedAt: Date
    let displayName: String?
    let birthData: BirthData?
    let journalEntries: [Journal]
    let people: [Person]
    let milestones: [Milestone]
    let exploredPlacements: [String]
    let preferences: [String: String]

    /// What this file does *not* contain, stated in the file itself — the same
    /// promise the privacy dashboard makes on screen.
    let notIncluded = [
        "No account password or authentication token (your Sign in with Apple session stays in the Keychain).",
        "No computed chart: it is derived from the birth data above and recomputed on demand, never stored on our servers.",
        "No analytics, advertising identifiers, or location history — Lumina collects none of these.",
    ]

    enum CodingKeys: String, CodingKey {
        case formatVersion, exportedAt, displayName, birthData, journalEntries
        case people, milestones, exploredPlacements, preferences, notIncluded
    }
}

extension LuminaDataExport {
    /// Gathers every on-device store. Mirrors the set the account eraser
    /// clears, so a store added to one is conspicuous by its absence in the
    /// other.
    @MainActor
    static func make(
        journalEntries: [JournalEntry],
        friends: [Friend],
        now: Date = .now
    ) -> LuminaDataExport {
        let preferences = AppPreferences.shared
        return LuminaDataExport(
            exportedAt: now,
            displayName: preferences.displayName.isEmpty ? nil : preferences.displayName,
            birthData: UserBirthDataStore.userDefaults.load(),
            journalEntries: journalEntries.sorted { $0.date < $1.date }.map(Journal.init(_:)),
            people: friends.sorted { $0.createdAt < $1.createdAt }.map(Person.init(_:)),
            milestones: MomentsStore.shared.unlocked.map {
                Milestone(name: $0.moment.title, unlockedAt: $0.date)
            },
            exploredPlacements: ChartDiscovery.shared.explored.sorted(),
            preferences: settings(preferences)
        )
    }

    private static func settings(_ preferences: AppPreferences) -> [String: String] {
        [
            "houseSystem": preferences.houseSystem.rawValue,
            "lockReflectWithFaceID": String(preferences.lockReflectWithFaceID),
            "reduceMotionOverride": String(preferences.reduceMotionOverride),
            "transitAlertsEnabled": String(preferences.transitAlertsEnabled),
            "reflectReminderEnabled": String(preferences.reflectReminderEnabled),
        ]
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}

/// A `FileDocument` wrapper so the export can go through `.fileExporter`,
/// which hands the user the system save sheet — Files, AirDrop, Mail, or any
/// other destination they already trust. Nothing is uploaded anywhere.
struct LuminaExportDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
