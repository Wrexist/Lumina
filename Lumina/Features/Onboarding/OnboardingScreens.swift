import SwiftUI

/// All 8 onboarding screen sub-views grouped under one namespace.
/// `BirthPlace` (with MapKit autocomplete) and `ChartReveal` (with the
/// real `EphemerisService` call) live in their own extension files
/// (`OnboardingScreens+Place.swift`, `OnboardingScreens+Reveal.swift`)
/// to keep this file under the SwiftLint length budget.
///
/// Each screen is a small, self-contained `View` that takes its piece of
/// `OnboardingState` via a binding and exposes nothing else. The
/// surrounding `OnboardingFlowView` owns navigation and validation.
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
        let inlineError: String?

        var body: some View {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                    Text("What should we call you?")
                        .font(LuminaTypography.heading)
                    HStack {
                        Text("Just a first name is fine.")
                            .font(LuminaTypography.bodyLight)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                        Spacer()
                        WhyWeAsk(
                            title: "Why we ask for your name",
                            body: "Lumina greets you by name in readings and journal prompts. We never share it; it stays on your device unless you sign in."
                        )
                    }
                }
                LuminaTextField(
                    title: "Your name",
                    text: $name,
                    placeholder: "Anna",
                    helper: "Used only inside the app to greet you.",
                    error: inlineError,
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
                    HStack {
                        Text("The date alone gets you a real chart. Time and place sharpen it.")
                            .font(LuminaTypography.bodyLight)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                        Spacer()
                        WhyWeAsk(
                            title: "Why we ask for your birth date",
                            body: "Your birth date sets every planet's exact position at the moment you were born. Without it, Lumina can't compute your chart."
                        )
                    }
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
                    HStack {
                        Text("Without time, we still calculate your sign and planets — only houses are hidden.")
                            .font(LuminaTypography.bodyLight)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                        Spacer()
                        WhyWeAsk(
                            title: "Why we ask for your birth time",
                            body: "The exact time decides your rising sign and which house each planet "
                                + "falls into. With time, every reading is sharper. Without it, the rest "
                                + "of your chart is still real."
                        )
                    }
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
