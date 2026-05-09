import SwiftUI

/// All 8 onboarding screen sub-views grouped under one namespace.
/// Each is a small, self-contained `View` that takes its piece of
/// `OnboardingState` via a binding and exposes nothing else. The
/// surrounding `OnboardingFlowView` owns navigation and validation.
///
/// These are still partial — the real flow (Phase 2 of the roadmap)
/// brings MapKit autocomplete, the chart-reveal SVG draw, and live
/// inline validation. What's already here: copy that follows the
/// clarity charter, "I don't know" paths, accessibility wiring.
enum OnboardingScreens {
    struct BrandPromise: View {
        var body: some View {
            VStack(spacing: LuminaSpacing.lg) {
                Spacer()
                Text("Lumina")
                    .font(LuminaTypography.display)
                    .foregroundStyle(LuminaColors.inkBlack)
                Text("Finally, a real one.")
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.celestialBlue)
                Spacer()
                Text("Real chart math. Real palm analysis. No fake mysticism.")
                    .font(LuminaTypography.bodyLight)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                    .padding(.horizontal, LuminaSpacing.lg)
            }
            .padding(LuminaSpacing.lg)
        }
    }

    struct Motivation: View {
        @Binding var selection: OnboardingState.Motivation?

        var body: some View {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                heading
                ForEach(OnboardingState.Motivation.allCases, id: \.self) { option in
                    motivationRow(option)
                }
                Spacer()
            }
            .padding(LuminaSpacing.lg)
        }

        private var heading: some View {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("Why are you here?")
                    .font(LuminaTypography.heading)
                Text("Your answer shapes the readings we send. You can change it later in Settings.")
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
        }

        private func motivationRow(_ option: OnboardingState.Motivation) -> some View {
            Button {
                selection = option
                Haptics.selection.play()
            } label: {
                HStack {
                    Text(option.label).font(LuminaTypography.body)
                    Spacer()
                    if selection == option {
                        Image(systemName: "checkmark")
                            .foregroundStyle(LuminaColors.celestialBlue)
                    }
                }
                .padding(LuminaSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LuminaColors.parchment)
                .luminaCornerRadius(LuminaRadii.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: LuminaRadii.sm, style: .continuous)
                        .stroke(
                            selection == option ? LuminaColors.celestialBlue : LuminaColors.inkBlack.opacity(0.2),
                            lineWidth: selection == option ? 2 : 1
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    struct Name: View {
        @Binding var name: String

        var body: some View {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                    Text("What should we call you?")
                        .font(LuminaTypography.heading)
                    Text("Just a first name is fine.")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                }
                LuminaTextField(
                    title: "Your name",
                    text: $name,
                    placeholder: "Anna",
                    helper: "Used only inside the app to greet you.",
                    textContentType: .givenName,
                    maxCharacters: 60
                )
                Spacer()
            }
            .padding(LuminaSpacing.lg)
        }
    }

    struct BirthDate: View {
        @Binding var date: Date?

        var body: some View {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                    Text("When were you born?")
                        .font(LuminaTypography.heading)
                    Text("The date alone gets you a real chart. Time and place sharpen it.")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                }
                DatePicker(
                    "Birth date",
                    selection: Binding(
                        get: { date ?? defaultDate },
                        set: { date = $0 }
                    ),
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            }
            .padding(LuminaSpacing.lg)
        }

        private var defaultDate: Date {
            Calendar.current.date(byAdding: .year, value: -28, to: .now) ?? .now
        }
    }

    struct BirthTime: View {
        @Binding var time: Date?
        @Binding var unknown: Bool

        var body: some View {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                    Text("What time?")
                        .font(LuminaTypography.heading)
                    Text("Without time, we still calculate your sign and planets — only houses are hidden.")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                }

                if !unknown {
                    DatePicker(
                        "Birth time",
                        selection: Binding(
                            get: { time ?? defaultTime },
                            set: { time = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }

                LuminaButton(
                    title: unknown ? "I'll add time later" : "I'm not sure",
                    variant: .ghost
                ) {
                    unknown.toggle()
                    if unknown { time = nil }
                }

                Spacer()
            }
            .padding(LuminaSpacing.lg)
        }

        private var defaultTime: Date {
            Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now) ?? .now
        }
    }

    struct BirthPlace: View {
        @Binding var placeName: String

        var body: some View {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                    Text("Where?")
                        .font(LuminaTypography.heading)
                    Text("City and country are enough. The full MapKit autocomplete + manual lat/lon path ships in Phase 2.")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                }
                LuminaTextField(
                    title: "Birth place",
                    text: $placeName,
                    placeholder: "Stockholm, Sweden",
                    helper: "We use this once to set your time zone, then forget it.",
                    textContentType: .addressCityAndState
                )
                Spacer()
            }
            .padding(LuminaSpacing.lg)
        }
    }

    struct ChartReveal: View {
        @Binding var ready: Bool

        var body: some View {
            VStack(spacing: LuminaSpacing.lg) {
                Spacer()
                Circle()
                    .stroke(LuminaColors.inkBlack.opacity(0.15), lineWidth: 1)
                    .frame(width: 240, height: 240)
                    .overlay(
                        Text(ready ? "Your chart is ready" : "Calculating your chart…")
                            .font(LuminaTypography.body)
                    )
                Spacer()
                Text("The animated wheel-draw + soft chime ships in Phase 4. For now we synthesise readiness so the rest of the flow is testable.")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LuminaSpacing.lg)
            }
            .padding(LuminaSpacing.lg)
            .task {
                guard !ready else { return }
                try? await Task.sleep(for: .seconds(1))
                ready = true
            }
        }
    }

    struct WhatNext: View {
        let onPick: () -> Void

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                    VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                        Text("What you can do next")
                            .font(LuminaTypography.heading)
                        Text("Pick one — you can come back to the others any time.")
                            .font(LuminaTypography.bodyLight)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                    }
                    quickWin("Read today", body: "Your transit-grounded reading, narrated.")
                    quickWin("Scan a hand", body: "On-device AI reads your palm in 4 seconds.")
                    quickWin("Add a friend", body: "Compare charts and see what's between you.")
                }
                .padding(LuminaSpacing.lg)
            }
        }

        private func quickWin(_ title: String, body: String) -> some View {
            Button {
                onPick()
            } label: {
                LuminaCard {
                    VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                        Text(title).font(LuminaTypography.heading)
                        Text(body)
                            .font(LuminaTypography.body)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}

extension OnboardingState.Motivation {
    var label: String {
        switch self {
        case .curious: "Just curious"
        case .selfUnderstanding: "Understand myself better"
        case .relationships: "Make sense of a relationship"
        case .timing: "Time a decision well"
        }
    }
}
