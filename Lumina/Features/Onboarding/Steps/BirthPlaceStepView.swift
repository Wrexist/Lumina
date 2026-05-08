import SwiftUI

/// Stub: a real city autocomplete (MapKit `MKLocalSearchCompleter`) lands
/// in a follow-up. For now the user types a free-form place name and we
/// keep latitude/longitude/timezone at their defaults — the backend
/// gracefully accepts any plausible coordinates.
struct BirthPlaceStepView: View {
    @Bindable var state: OnboardingState

    var body: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
            Spacer()
            Text("Where were you born?")
                .font(LuminaTypography.heading)
                .foregroundStyle(LuminaColors.inkBlack)
            TextField("City, Country", text: $state.birthPlaceName)
                .font(LuminaTypography.body)
                .textInputAutocapitalization(.words)
                .padding(LuminaSpacing.md)
                .background(LuminaColors.parchment.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(LuminaColors.inkBlack.opacity(0.2), lineWidth: 1)
                )
            // TODO(lumina): wire MKLocalSearchCompleter to populate latitude,
            // longitude, and timeZoneIdentifier from the chosen suggestion.
            Spacer()
            OnboardingNextButton(
                state: state,
                isEnabled: !state.birthPlaceName.trimmingCharacters(in: .whitespaces).isEmpty
            )
        }
    }
}
