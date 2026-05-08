import Foundation
import Observation

/// Drives the 8-step onboarding flow. Owns the in-progress birth data
/// and motivation selection; the final `birthData` is fed to
/// `EphemerisService.chart(for:)` once the chart-reveal step runs.
@MainActor
@Observable
final class OnboardingState {
    enum Step: Int, CaseIterable, Hashable {
        case welcome
        case name
        case birthDate
        case birthTime
        case birthPlace
        case motivation
        case chartReveal
        case palmIntro
        case paywall

        var isFirst: Bool { self == .welcome }
        var isLast: Bool { self == .paywall }
    }

    /// Used to personalize paywall + content; tracked here so the same
    /// motivation pulls through to the daily reading and chart reveal.
    enum Motivation: String, CaseIterable, Hashable, Identifiable {
        case selfDiscovery
        case relationships
        case career
        case daily

        var id: String { rawValue }

        var label: String {
            switch self {
            case .selfDiscovery: return "Understand myself"
            case .relationships: return "Decode my relationships"
            case .career: return "Find my path"
            case .daily: return "Daily clarity"
            }
        }
    }

    var currentStep: Step = .welcome
    var name: String = ""
    var birthDate: Date = .init()
    var birthTime: Date?
    var isBirthTimeUnknown: Bool = false
    var birthPlaceName: String = ""
    var birthLatitude: Double = .zero
    var birthLongitude: Double = .zero
    var birthTimeZoneIdentifier: String = TimeZone.current.identifier
    var motivation: Motivation?

    func advance() {
        guard let next = Step(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
    }

    func goBack() {
        guard let previous = Step(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = previous
    }

    func birthData() -> BirthData {
        BirthData(
            birthDate: birthDate,
            birthTime: isBirthTimeUnknown ? nil : birthTime,
            placeName: birthPlaceName,
            latitude: birthLatitude,
            longitude: birthLongitude,
            timeZoneIdentifier: birthTimeZoneIdentifier
        )
    }
}
