import SwiftUI

/// Stub: the real RevenueCat-backed paywall lands in a follow-up. This
/// step exists so the onboarding flow has a terminal state and so the
/// hard-paywall position (per CLAUDE.md "Critical Rules") is visible
/// in the navigation graph.
struct PaywallStepView: View {
    let state: OnboardingState

    var body: some View {
        VStack(spacing: LuminaSpacing.xl) {
            Spacer()
            Text("Lumina Plus")
                .font(LuminaTypography.display)
                .foregroundStyle(LuminaColors.inkBlack)
            Text("Daily readings, full charts, palm reading.")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, LuminaSpacing.lg)
            // TODO(lumina): wire `IAPManager` here — Apple Guideline 3.1.2(c)
            // means hard paywall + ONE soft 30%-off rescue, then hard stop.
            Spacer()
            Text("Paywall coming in a follow-up commit.")
                .font(LuminaTypography.caption)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.5))
        }
    }
}
