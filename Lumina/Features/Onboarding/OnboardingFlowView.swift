import SwiftUI

/// Root of the onboarding flow. Switches the visible step view on the
/// `state.currentStep` enum and provides a parchment background.
struct OnboardingFlowView: View {
    @State private var state = OnboardingState()

    var body: some View {
        ZStack {
            LuminaColors.parchment.ignoresSafeArea()
            currentStepView
                .padding(LuminaSpacing.lg)
                .animation(.smooth, value: state.currentStep)
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch state.currentStep {
        case .welcome: WelcomeStepView(state: state)
        case .name: NameStepView(state: state)
        case .birthDate: BirthDateStepView(state: state)
        case .birthTime: BirthTimeStepView(state: state)
        case .birthPlace: BirthPlaceStepView(state: state)
        case .motivation: MotivationStepView(state: state)
        case .chartReveal: ChartRevealStepView(state: state)
        case .palmIntro: PalmIntroStepView(state: state)
        case .paywall: PaywallStepView(state: state)
        }
    }
}

#Preview {
    OnboardingFlowView()
}
