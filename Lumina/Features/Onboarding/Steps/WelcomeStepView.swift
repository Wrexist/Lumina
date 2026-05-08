import SwiftUI

struct WelcomeStepView: View {
    let state: OnboardingState

    var body: some View {
        VStack(spacing: LuminaSpacing.xl) {
            Spacer()
            Text("Lumina")
                .font(LuminaTypography.display)
                .foregroundStyle(LuminaColors.inkBlack)
            Text("Finally, a real one.")
                .font(LuminaTypography.heading)
                .foregroundStyle(LuminaColors.celestialBlue)
                .multilineTextAlignment(.center)
            Spacer()
            Button("Begin", action: state.advance)
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.parchment)
                .padding(.horizontal, LuminaSpacing.xl)
                .padding(.vertical, LuminaSpacing.md)
                .background(LuminaColors.inkBlack, in: Capsule())
        }
    }
}
