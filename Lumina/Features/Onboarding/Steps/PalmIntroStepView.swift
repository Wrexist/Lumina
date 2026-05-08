import SwiftUI

struct PalmIntroStepView: View {
    let state: OnboardingState

    var body: some View {
        VStack(spacing: LuminaSpacing.xl) {
            Spacer()
            Text("Read your palm next?")
                .font(LuminaTypography.heading)
                .foregroundStyle(LuminaColors.inkBlack)
                .multilineTextAlignment(.center)
            Text("On-device only. The photo never leaves your phone.")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, LuminaSpacing.lg)
            Spacer()
            VStack(spacing: LuminaSpacing.md) {
                OnboardingNextButton(state: state, isEnabled: true, label: "Scan my palm")
                Button("Maybe later", action: state.advance)
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            }
        }
    }
}
