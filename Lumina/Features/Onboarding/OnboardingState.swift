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
    var birthDate: Date?
    var birthTime: Date?
    var birthTimeUnknown: Bool
    var birthPlaceName: String

    /// `true` once the chart has been computed and we can advance to the
    /// final "what's next" step.
    var chartReady = false

    private var snapshot: OnboardingSnapshot {
        OnboardingSnapshot(
            currentStep: currentStep,
            motivation: motivation,
            name: name,
            birthDate: birthDate,
            birthTime: birthTime,
            birthTimeUnknown: birthTimeUnknown,
            birthPlaceName: birthPlaceName
        )
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
    }

    /// `true` if the field captured at `step` is sufficient to move forward.
    func canAdvance(from step: Step) -> Bool {
        switch step {
        case .brandPromise: true
        case .motivation: motivation != nil
        case .name: !name.trimmingCharacters(in: .whitespaces).isEmpty
        case .birthDate: birthDate != nil
        case .birthTime: birthTimeUnknown || birthTime != nil
        case .birthPlace: !birthPlaceName.trimmingCharacters(in: .whitespaces).isEmpty
        case .chartReveal: chartReady
        case .whatNext: true
        }
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
    var name: String = ""
    var birthDate: Date?
    var birthTime: Date?
    var birthTimeUnknown = false
    var birthPlaceName: String = ""
}
