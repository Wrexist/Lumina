import SwiftUI

/// Orchestrates the 8-screen onboarding flow per `ROADMAP.md` Phase 2 and
/// `docs/NAVIGATION.md` §6. Each screen is a small dedicated view; this
/// orchestrator owns the `OnboardingState`, the progress bar, and the
/// next/back chrome.
///
/// The screens themselves are still copy-stubs in this commit — Phase 2
/// of the roadmap fleshes them out (real DatePicker, MapKit, chart-reveal
/// animation). What's already correct: progression, validation gates,
/// resume-on-kill persistence, and the "I don't know my time" path.
struct OnboardingFlowView: View {
    @State private var state = OnboardingState()
    @State private var ephemeris = EphemerisService()
    let onComplete: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            LuminaColors.parchment.ignoresSafeArea()

            VStack(spacing: LuminaSpacing.lg) {
                topBar
                    .padding(.horizontal, LuminaSpacing.lg)
                    .padding(.top, LuminaSpacing.md)

                contentForCurrentStep
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomBar
                    .padding(.horizontal, LuminaSpacing.lg)
                    .padding(.bottom, LuminaSpacing.lg)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                state.goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(LuminaColors.inkBlack.opacity(state.currentStep.index == 0 ? 0 : 0.7))
            }
            .accessibilityLabel("Back")
            .disabled(state.currentStep.index == 0)

            Spacer()

            OnboardingProgressBar(
                total: OnboardingState.Step.totalCount,
                current: state.currentStep.index
            )

            Spacer()

            // Keep chevron-shaped placeholder so the title is centered.
            Image(systemName: "chevron.left").opacity(0)
        }
    }

    @ViewBuilder
    private var contentForCurrentStep: some View {
        switch state.currentStep {
        case .brandPromise:
            OnboardingScreens.BrandPromise()
        case .motivation:
            OnboardingScreens.Motivation(selection: $state.motivation)
        case .name:
            OnboardingScreens.Name(
                name: $state.name,
                inlineError: state.validationMessage(for: .name)
            )
        case .birthDate:
            OnboardingScreens.BirthDate(date: $state.birthDate)
        case .birthTime:
            OnboardingScreens.BirthTime(time: $state.birthTime, unknown: $state.birthTimeUnknown)
        case .birthPlace:
            OnboardingScreens.BirthPlace(state: state)
        case .chartReveal:
            OnboardingScreens.ChartReveal(state: state, ephemeris: ephemeris)
        case .whatNext:
            OnboardingScreens.WhatNext { onComplete() }
        }
    }

    private var bottomBar: some View {
        let isFinal = state.currentStep == .whatNext
        let title = isFinal ? "Take me to Today" : "Continue"
        return LuminaButton(
            title: title,
            variant: .primary,
            isEnabled: state.canAdvance(from: state.currentStep)
        ) {
            if isFinal {
                onComplete()
            } else {
                state.advance()
            }
        }
    }
}

#Preview {
    OnboardingFlowView(onComplete: { })
}
