import SwiftUI

struct BirthDateStepView: View {
    @Bindable var state: OnboardingState

    var body: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
            Spacer()
            Text("When were you born?")
                .font(LuminaTypography.heading)
                .foregroundStyle(LuminaColors.inkBlack)
            DatePicker(
                "Birth date",
                selection: $state.birthDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            Spacer()
            OnboardingNextButton(state: state, isEnabled: true)
        }
    }
}
