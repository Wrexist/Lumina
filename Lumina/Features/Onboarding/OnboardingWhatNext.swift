import SwiftUI

/// The last onboarding step: three things worth doing first.
///
/// Its own file rather than another case in `OnboardingScreens` — that enum
/// is at SwiftLint's type-body ceiling, and this screen carries real logic
/// (it orders itself by the motivation the user gave on step two) rather than
/// being a static layout like the others.
extension OnboardingScreens {
    struct WhatNext: View {
        /// What the user said they came for, on the second onboarding screen.
        /// Used to lead with the matching destination — the screen asked the
        /// question and then ignored the answer, which is worse than not
        /// asking.
        var motivation: OnboardingState.Motivation?
        let onPick: (LuminaDeepLink) -> Void

        private struct QuickWin {
            let title: String
            let body: String
            let destination: LuminaDeepLink
            let servesMotivation: OnboardingState.Motivation
        }

        private static let quickWins: [QuickWin] = [
            QuickWin(
                title: "Read today",
                body: "Your reading, grounded in today's real transits.",
                destination: .today,
                servesMotivation: .timing
            ),
            QuickWin(
                title: "See your chart",
                body: "The full wheel — tap any planet to explore it.",
                destination: .chart(planet: nil),
                servesMotivation: .selfUnderstanding
            ),
            QuickWin(
                title: "Add a friend",
                body: "Compare charts and see what's between you.",
                destination: .people(friendID: nil),
                servesMotivation: .relationships
            ),
        ]

        /// The matching destination first. `.curious` matches nothing in
        /// particular, so that order is left as authored.
        private var ordered: [QuickWin] {
            guard let motivation, motivation != .curious else { return Self.quickWins }
            return Self.quickWins.sorted { lhs, _ in lhs.servesMotivation == motivation }
        }

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
                    ForEach(ordered, id: \.title) { win in
                        quickWin(win.title, body: win.body, destination: win.destination)
                    }
                }
                .padding(LuminaSpacing.lg)
            }
        }

        private func quickWin(_ title: String, body: String, destination: LuminaDeepLink) -> some View {
            Button {
                onPick(destination)
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
