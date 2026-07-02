import Foundation
import OSLog
import SwiftUI

/// The 8-step onboarding flow as a state machine. Persists to
/// `UserDefaults` so a force-quit at step N relaunches at step N with the
/// captured fields intact (`docs/NAVIGATION.md` §6).
///
/// Phase 2 of `ROADMAP.md` builds the real screens against this model;
/// the placeholder shell (`OnboardingFlowView`) already routes through it
/// so persistence is testable from day one.
@MainActor
@Observable
final class OnboardingState {
    enum Step: Int, CaseIterable, Codable, Sendable {
        case brandPromise
        case motivation
        case name
        case birthDate
        case birthTime
        case birthPlace
        case chartReveal
        case whatNext

        var index: Int { rawValue }
        static var totalCount: Int { allCases.count }
    }

    enum Motivation: String, CaseIterable, Codable, Sendable {
        case curious
        case selfUnderstanding
        case relationships
        case timing
    }

    private let logger = Logger(subsystem: "app.lumina.ios", category: "Onboarding")
    private let storage: OnboardingStorage

    var currentStep: Step
    var motivation: Motivation?
    var name: String
    // Any birth-field edit invalidates a previously computed chart so
    // going back from the reveal and changing a value recomputes instead
    // of showing the old chart.
    var birthDate: Date? {
        didSet { if oldValue != birthDate { chartReady = false } }
    }
    var birthTime: Date? {
        didSet { if oldValue != birthTime { chartReady = false } }
    }
    var birthTimeUnknown: Bool {
        didSet { if oldValue != birthTimeUnknown { chartReady = false } }
    }
    var birthPlaceName: String
    var birthLatitude: Double?
    var birthLongitude: Double?
    var birthTimeZoneIdentifier: String?

    /// `true` once the chart has been computed and we can advance to the
    /// final "what's next" step.
    var chartReady = false

    /// Inline error surfaced by the current step (e.g. couldn't resolve a
    /// city). Cleared when the user changes the field.
    var stepError: LuminaError?

    private var snapshot: OnboardingSnapshot {
        OnboardingSnapshot(
            currentStep: currentStep,
            motivation: motivation,
            name: name,
            birthDate: birthDate,
            birthTime: birthTime,
            birthTimeUnknown: birthTimeUnknown,
            birthPlaceName: birthPlaceName,
            birthLatitude: birthLatitude,
            birthLongitude: birthLongitude,
            birthTimeZoneIdentifier: birthTimeZoneIdentifier
        )
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var birthPlaceResolved: Bool {
        !birthPlaceName.trimmingCharacters(in: .whitespaces).isEmpty
            && birthLatitude != nil
            && birthLongitude != nil
            && birthTimeZoneIdentifier != nil
    }

    init(storage: OnboardingStorage = .userDefaults) {
        self.storage = storage
        let snapshot = storage.load()
        self.currentStep = snapshot.currentStep
        self.motivation = snapshot.motivation
        self.name = snapshot.name
        self.birthDate = snapshot.birthDate
        self.birthTime = snapshot.birthTime
        self.birthTimeUnknown = snapshot.birthTimeUnknown
        self.birthPlaceName = snapshot.birthPlaceName
        self.birthLatitude = snapshot.birthLatitude
        self.birthLongitude = snapshot.birthLongitude
        self.birthTimeZoneIdentifier = snapshot.birthTimeZoneIdentifier
    }

    /// `true` if the field captured at `step` is sufficient to move forward.
    func canAdvance(from step: Step) -> Bool {
        switch step {
        case .brandPromise: true
        case .motivation: motivation != nil
        case .name: trimmedName.count >= 2
        case .birthDate: birthDate.map { $0 <= .now } ?? false
        case .birthTime: birthTimeUnknown || birthTime != nil
        case .birthPlace: birthPlaceResolved
        case .chartReveal: chartReady
        case .whatNext: true
        }
    }

    /// Inline validation message for the current step, or `nil` if the
    /// step is happy. Displayed under the relevant field as the user types.
    func validationMessage(for step: Step) -> String? {
        switch step {
        case .name:
            let trimmed = trimmedName
            if trimmed.isEmpty { return nil }
            if trimmed.count < 2 { return "A bit longer please — at least 2 characters." }
            return nil
        case .birthDate:
            guard let date = birthDate else { return nil }
            return date > .now ? "Birth date can't be in the future." : nil
        case .birthPlace:
            if birthPlaceName.isEmpty { return nil }
            return birthPlaceResolved ? nil : "Pick a suggestion so we can find your time zone."
        default:
            return nil
        }
    }

    /// Builds the `BirthData` payload used by `EphemerisService.chart(...)`
    /// on the chart-reveal step. Returns `nil` until every required field
    /// is populated.
    func makeBirthData() -> BirthData? {
        guard let birthDate,
              let latitude = birthLatitude,
              let longitude = birthLongitude,
              let timeZoneIdentifier = birthTimeZoneIdentifier else {
            return nil
        }
        return BirthData.fromPickers(
            pickedDay: birthDate,
            pickedTime: birthTimeUnknown ? nil : birthTime,
            placeName: birthPlaceName,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }

    /// Records a resolved place from `BirthPlaceSearch`. The user can re-tap
    /// suggestions; we always overwrite the prior coordinates.
    func applyResolvedPlace(name: String, latitude: Double, longitude: Double, timeZoneIdentifier: String) {
        birthPlaceName = name
        birthLatitude = latitude
        birthLongitude = longitude
        birthTimeZoneIdentifier = timeZoneIdentifier
        chartReady = false
        stepError = nil
        persist()
    }

    /// Clears coordinate state when the user starts typing a new place.
    func clearResolvedPlace() {
        birthLatitude = nil
        birthLongitude = nil
        birthTimeZoneIdentifier = nil
    }

    /// Advances to the next step if the current one is valid. Persists on
    /// every transition so a kill anywhere in the flow is recoverable.
    func advance() {
        guard canAdvance(from: currentStep) else {
            logger.debug("blocked advance — step \(self.currentStep.index) not satisfied")
            return
        }
        let next = Step(rawValue: currentStep.index + 1)
        if let next {
            currentStep = next
        }
        persist()
    }

    /// Walks backwards. No-op on the first step.
    func goBack() {
        guard let previous = Step(rawValue: currentStep.index - 1) else { return }
        currentStep = previous
        persist()
    }

    func persist() {
        storage.save(snapshot)
    }
}

/// Persisted shape — kept as a separate `Codable` struct so we can iterate
/// the in-memory `OnboardingState` model without breaking the on-disk
/// format. Versioning ships in v1.1 if the field set changes.
struct OnboardingSnapshot: Codable, Sendable {
    var currentStep: OnboardingState.Step = .brandPromise
    var motivation: OnboardingState.Motivation?
    var name = ""
    var birthDate: Date?
    var birthTime: Date?
    var birthTimeUnknown = false
    var birthPlaceName = ""
    var birthLatitude: Double?
    var birthLongitude: Double?
    var birthTimeZoneIdentifier: String?
}
