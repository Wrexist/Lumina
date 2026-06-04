import SwiftUI

extension OnboardingScreens {
    /// Step 6 — birth place. Drives MapKit autocomplete via
    /// `BirthPlaceSearch`. The user must pick a suggestion before
    /// `OnboardingState.canAdvance(from: .birthPlace)` returns true so we
    /// always have coordinates + IANA time zone for the chart.
    struct BirthPlace: View {
        @Bindable var state: OnboardingState
        @State private var search = BirthPlaceSearch()
        @State private var query = ""
        @State private var resolveError: String?
        @State private var manualSheet = false

        var body: some View {
            VStack(alignment: .leading, spacing: LuminaSpacing.md) {
                heading
                LuminaTextField(
                    title: "Birth place",
                    text: queryBinding,
                    placeholder: "Stockholm, Sweden",
                    helper: state.birthLatitude == nil
                        ? "Start typing — pick a city from the list."
                        : "Time zone set automatically.",
                    error: resolveError ?? state.validationMessage(for: .birthPlace),
                    textContentType: .addressCityAndState
                )
                suggestionList
                LuminaButton(title: "Enter coordinates manually", variant: .ghost) {
                    manualSheet = true
                }
                Spacer()
            }
            .padding(LuminaSpacing.lg)
            .sheet(isPresented: $manualSheet) {
                ManualBirthPlaceSheet(state: state)
            }
        }

        private var heading: some View {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("Where?")
                    .font(LuminaTypography.heading)
                HStack {
                    Text("City and country are enough.")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                    Spacer()
                    WhyWeAsk(
                        title: "Why we ask for your birth place",
                        body: "Your time zone at birth — including any historic shifts — comes from the city. We use it once to anchor your chart, then keep only the city name."
                    )
                }
            }
        }

        @ViewBuilder
        private var suggestionList: some View {
            if !search.suggestions.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(search.suggestions) { suggestion in
                            suggestionRow(suggestion)
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 260)
                .background(LuminaColors.parchment)
                .luminaCornerRadius(LuminaRadii.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: LuminaRadii.sm, style: .continuous)
                        .stroke(LuminaColors.inkBlack.opacity(0.12), lineWidth: 1)
                )
            }
        }

        private var queryBinding: Binding<String> {
            Binding(
                get: { query },
                set: { newValue in
                    query = newValue
                    state.birthPlaceName = newValue
                    if state.birthLatitude != nil {
                        state.clearResolvedPlace()
                    }
                    search.update(query: newValue)
                }
            )
        }

        private func suggestionRow(_ suggestion: BirthPlaceSearch.Suggestion) -> some View {
            Button {
                Task { await pick(suggestion) }
            } label: {
                VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                    Text(suggestion.title)
                        .font(LuminaTypography.body)
                        .foregroundStyle(LuminaColors.inkBlack)
                    if !suggestion.subtitle.isEmpty {
                        Text(suggestion.subtitle)
                            .font(LuminaTypography.caption)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(LuminaSpacing.md)
            }
            .buttonStyle(.plain)
        }

        private func pick(_ suggestion: BirthPlaceSearch.Suggestion) async {
            do {
                let resolved = try await search.resolve(suggestion)
                state.applyResolvedPlace(
                    name: resolved.displayName,
                    latitude: resolved.latitude,
                    longitude: resolved.longitude,
                    timeZoneIdentifier: resolved.timeZoneIdentifier
                )
                query = resolved.displayName
                resolveError = nil
                Haptics.success.play()
            } catch {
                resolveError = LuminaError.from(error).userBody
                Haptics.failure.play()
            }
        }
    }
}
