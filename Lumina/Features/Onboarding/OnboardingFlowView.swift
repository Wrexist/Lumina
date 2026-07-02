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
    @State private var paywall = PaywallTracker.shared
    @State private var paywallPresented = false
    @State private var paywallVariant: PaywallOfferView.Variant = .initial
    @Environment(\.scenePhase) private var scenePhase
    @State private var pendingDestination: LuminaDeepLink?
    /// One-time completion guard: the trial purchase runs in a `Task`, so a
    /// second final-step tap could otherwise call `onComplete` twice.
    @State private var didComplete = false
    /// Called when onboarding finishes. The optional deep link is the tab the
    /// user chose on the "what next" screen (nil = land on Today).
    let onComplete: (LuminaDeepLink?) -> Void

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
        .fullScreenCover(isPresented: $paywallPresented) {
            PaywallOfferView(
                variant: paywallVariant,
                onStartTrial: handleStartTrial,
                onContinueFree: handleContinueFree
            )
        }
        .onChange(of: scenePhase) { _, phase in
            // Persist mid-step edits when backgrounded so a force-quit resumes
            // exactly where the user left off (docs/NAVIGATION.md §6).
            if phase != .active { state.persist() }
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
            Image(systemName: "chevron.left").opacity(0).accessibilityHidden(true)
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
            OnboardingScreens.WhatNext { handleFinalTap($0) }
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
                handleFinalTap(nil)
            } else {
                state.advance()
            }
        }
    }

    /// Final-step tap. The first time, present the paywall offer as a
    /// non-blocking full-screen cover. After the user has seen (and
    /// declined) it, subsequent finals route straight to MainTabs.
    private func handleFinalTap(_ destination: LuminaDeepLink?) {
        pendingDestination = destination
        if paywall.hasSeenInitialOffer {
            // Still persist: skipping straight to `onComplete` here would
            // finish onboarding without ever saving the captured birth data.
            persistAndComplete()
        } else {
            paywallVariant = .initial
            paywallPresented = true
        }
    }

    private func handleStartTrial() {
        paywall.recordInitialOfferSeen()
        if paywallVariant == .rescue {
            paywall.recordRescueShown()
        }
        paywallPresented = false
        // Never trap the user behind a stuck paywall — success, failure, and
        // user-cancellation all land on the same "continue free" completion,
        // matching `handleContinueFree`'s philosophy below.
        Task {
            _ = try? await IAPManager.shared.purchaseCurrentOffering()
            persistAndComplete()
        }
    }

    private func handleContinueFree() {
        switch paywallVariant {
        case .initial:
            paywall.recordInitialOfferSeen()
            if paywall.shouldShowRescue() {
                // Swap the cover's content to the rescue offer *in place*. A
                // fullScreenCover(item:) won't reliably re-present on a
                // non-nil → non-nil change, so we keep a single cover up and
                // change only the variant it renders.
                paywallVariant = .rescue
            } else {
                paywallPresented = false
                persistAndComplete()
            }
        case .rescue:
            paywall.recordRescueShown()
            paywallPresented = false
            persistAndComplete()
        }
    }

    /// Writes the captured `BirthData` into the persistent store before
    /// completing onboarding so every other tab can read from one source.
    private func persistAndComplete() {
        guard !didComplete else { return }
        didComplete = true
        if let birthData = state.makeBirthData() {
            UserBirthDataStore.userDefaults.save(birthData)
        }
        onComplete(pendingDestination)
    }
}

#Preview {
    OnboardingFlowView { _ in }
}
