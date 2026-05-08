import SwiftUI

struct MotivationStepView: View {
    @Bindable var state: OnboardingState

    var body: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
            Spacer()
            Text("What brought you here?")
                .font(LuminaTypography.heading)
                .foregroundStyle(LuminaColors.inkBlack)
            VStack(spacing: LuminaSpacing.md) {
                ForEach(OnboardingState.Motivation.allCases) { motivation in
                    motivationButton(motivation)
                }
            }
            Spacer()
            OnboardingNextButton(state: state, isEnabled: state.motivation != nil)
        }
    }

    @ViewBuilder
    private func motivationButton(_ motivation: OnboardingState.Motivation) -> some View {
        let isSelected = state.motivation == motivation
        Button {
            state.motivation = motivation
        } label: {
            HStack {
                Text(motivation.label)
                    .font(LuminaTypography.body)
                Spacer()
            }
            .padding(LuminaSpacing.md)
            .foregroundStyle(isSelected ? LuminaColors.parchment : LuminaColors.inkBlack)
            .background(
                isSelected ? LuminaColors.celestialBlue : LuminaColors.parchment.opacity(0.7),
                in: RoundedRectangle(cornerRadius: 8)
            )
        }
    }
}
