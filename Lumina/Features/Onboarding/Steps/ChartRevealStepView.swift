import SwiftUI

/// Stub: the real chart-reveal animation (slow Canvas wheel draw + Lottie
/// particles) lands in a follow-up. For now we show a placeholder and
/// move on. The natal chart fetch from `EphemerisService.chart(for:)`
/// also wires up here in the next session.
struct ChartRevealStepView: View {
    let state: OnboardingState

    var body: some View {
        VStack(spacing: LuminaSpacing.xl) {
            Spacer()
            Text("Drawing your chart…")
                .font(LuminaTypography.heading)
                .foregroundStyle(LuminaColors.inkBlack)
            Circle()
                .stroke(LuminaColors.mutedGold, lineWidth: 1)
                .frame(width: 220, height: 220)
                .overlay(
                    Text("✶")
                        .font(LuminaTypography.display)
                        .foregroundStyle(LuminaColors.midnight)
                )
            // TODO(lumina): call EphemerisService.chart(for: state.birthData())
            // and animate planets onto the wheel before advancing.
            Spacer()
            OnboardingNextButton(state: state, isEnabled: true)
        }
    }
}
