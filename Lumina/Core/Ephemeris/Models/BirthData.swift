import Foundation

/// Captured at onboarding. `birthTime == nil` triggers a "noon-only" chart
/// (houses, Ascendant, MC, DC are hidden) per LEARNINGS.md.
struct BirthData: Codable, Hashable, Sendable {
    let birthDate: Date
    let birthTime: Date?
    let placeName: String
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String
}
