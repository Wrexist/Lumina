import SwiftUI

struct BirthTimeStepView: View {
    @Bindable var state: OnboardingState

    var body: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
            Spacer()
            Text("What time?")
                .font(LuminaTypography.heading)
                .foregroundStyle(LuminaColors.inkBlack)
            DatePicker(
                "Birth time",
                selection: Binding(
                    get: { state.birthTime ?? state.birthDate },
                    set: { state.birthTime = $0 }
                ),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .disabled(state.isBirthTimeUnknown)
            Toggle("I don't know", isOn: $state.isBirthTimeUnknown)
                .font(LuminaTypography.body)
                .tint(LuminaColors.celestialBlue)
            Text(state.isBirthTimeUnknown ? "We'll use noon — houses will be hidden." : " ")
                .font(LuminaTypography.caption)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            Spacer()
            OnboardingNextButton(state: state, isEnabled: true)
        }
    }
}
