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
    @State private var paywall = PaywallTracker.shared
    @State private var paywallPresented = false
    @State private var paywallVariant: PaywallOfferView.Variant = .initial
    /// True while a purchase is resolving, so the paywall can show progress
    /// instead of vanishing and leaving a dead screen behind it.
    @State private var purchaseInFlight = false
    /// Set when a purchase genuinely fails, so the user is told rather than
    /// dropped into the free app believing they subscribed.
    @State private var purchaseError: LuminaError?
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

                // Six of the eight steps had no ScrollView, and this fixed
                // frame sits between a top bar and a 56pt button. At
                // Accessibility XL on an iPhone SE the birth-time step —
                // heading + "Why we ask" + a 216pt wheel picker + the
                // "I'm not sure" ghost button — pushed that escape hatch off
                // screen, making the documented unknown-birth-time path
                // unreachable. docs/NAVIGATION.md §17 requires no truncation
                // at AX XL.
                //
                // `.basedOnSize` keeps the steps that already fit from
                // gaining a bouncy scroll they don't need.
                ScrollView {
                    contentForCurrentStep
                        .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(maxHeight: .infinity)

                bottomBar
                    .padding(.horizontal, LuminaSpacing.lg)
                    .padding(.bottom, LuminaSpacing.lg)
            }
        }
        .fullScreenCover(isPresented: $paywallPresented) {
            PaywallOfferView(
                variant: paywallVariant,
                purchaseInFlight: purchaseInFlight,
                purchaseError: purchaseError,
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
            OnboardingScreens.ChartReveal(state: state)
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

    private func handleStartTrial(_ plan: IAPManager.PremiumPlan) {
        paywall.recordInitialOfferSeen()
        if paywallVariant == .rescue {
            paywall.recordRescueShown()
        }
        // Keep the cover up while the purchase resolves. Dismissing first
        // meant the paywall vanished instantly, a beat of dead onboarding
        // screen went by, and *then* Apple's payment sheet appeared from
        // nowhere — and because the result was discarded with `try?`, a
        // failed purchase was indistinguishable from a successful one. A
        // user whose RevenueCat offering wasn't provisioned tapped the
        // primary CTA, got a silent no-op, and landed in the app believing
        // they had subscribed.
        purchaseInFlight = true
        purchaseError = nil
        Task {
            defer { purchaseInFlight = false }
            do {
                _ = try await IAPManager.shared.purchase(plan: plan)
                // Success *and* user-cancellation both continue into the app —
                // we never trap someone behind a paywall. The entitlement
                // itself is what gates features, so there's nothing to check
                // here beyond having surfaced any real error.
                paywallPresented = false
                persistAndComplete()
            } catch {
                // Real failure (not configured, no offering, StoreKit error).
                // Tell the user rather than pretending it worked.
                purchaseError = LuminaError.from(error)
            }
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
    /// Reached from both final-step paths (paywall flow and the
    /// paywall-already-seen shortcut), so the snapshot cleanup below covers
    /// every way out of onboarding.
    private func persistAndComplete() {
        guard !didComplete else { return }
        didComplete = true
        if let birthData = state.makeBirthData() {
            UserBirthDataStore.userDefaults.save(birthData)
        }
        // Keep the name the user gave us. Onboarding gated Continue on it and
        // then dropped it here, so we asked for something personal and did
        // nothing with it.
        AppPreferences.shared.displayName = state.trimmedName
        // Privacy: the resume-on-kill snapshot (name + full birth data) has
        // served its purpose now that the data lives in `UserBirthDataStore`.
        // Drop it so the Privacy dashboard's "Onboarding state: Cleared" is
        // truthful. Routing is unaffected — `AppRouterStorage` keeps its own
        // separate onboarding-done flag.
        OnboardingStorage.userDefaults.clear()
        onComplete(pendingDestination)
    }
}

#Preview {
    OnboardingFlowView { _ in }
}
