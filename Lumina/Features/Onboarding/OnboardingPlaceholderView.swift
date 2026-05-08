import SwiftUI

/// Phase-2 placeholder. The real 8-screen flow ships per `ROADMAP.md`
/// Phase 2; this single screen exists so the rest of the app shell can be
/// exercised before that flow is built.
struct OnboardingPlaceholderView: View {
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            LuminaColors.parchment.ignoresSafeArea()

            VStack(spacing: LuminaSpacing.lg) {
                Spacer()

                Text("Lumina")
                    .font(LuminaTypography.display)
                    .foregroundStyle(LuminaColors.inkBlack)

                Text("Finally, a real one.")
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.celestialBlue)

                Spacer()

                LuminaCard {
                    VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                        LuminaBadge(title: "Coming soon", tone: .neutral)
                        Text("Real onboarding ships in Phase 2 of the roadmap. For now, tap below to enter the app shell.")
                            .font(LuminaTypography.body)
                    }
                }

                LuminaButton(title: "Enter Lumina", variant: .primary) {
                    onComplete()
                }
            }
            .padding(LuminaSpacing.lg)
        }
    }
}

#Preview {
    OnboardingPlaceholderView(onComplete: {})
}
