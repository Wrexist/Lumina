import SwiftUI

struct NameStepView: View {
    @Bindable var state: OnboardingState

    var body: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
            Spacer()
            Text("What should we call you?")
                .font(LuminaTypography.heading)
                .foregroundStyle(LuminaColors.inkBlack)
            TextField("Your name", text: $state.name)
                .font(LuminaTypography.body)
                .textInputAutocapitalization(.words)
                .padding(LuminaSpacing.md)
                .background(LuminaColors.parchment.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(LuminaColors.inkBlack.opacity(0.2), lineWidth: 1)
                )
            Spacer()
            OnboardingNextButton(state: state, isEnabled: !state.name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}
