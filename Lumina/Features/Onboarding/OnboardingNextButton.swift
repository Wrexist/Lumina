import SwiftUI

/// Shared "Next" button used across the onboarding step views. Disables
/// itself when the step's preconditions aren't met; tapping advances
/// the state machine.
struct OnboardingNextButton: View {
    let state: OnboardingState
    let isEnabled: Bool
    var label = "Next"

    var body: some View {
        Button(label, action: state.advance)
            .font(LuminaTypography.body)
            .foregroundStyle(LuminaColors.parchment)
            .frame(maxWidth: .infinity)
            .padding(.vertical, LuminaSpacing.md)
            .background(
                isEnabled ? LuminaColors.inkBlack : LuminaColors.inkBlack.opacity(0.3),
                in: Capsule()
            )
            .disabled(!isEnabled)
    }
}
