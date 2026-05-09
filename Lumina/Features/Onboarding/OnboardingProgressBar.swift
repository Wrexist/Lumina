import SwiftUI

/// 8-dot progress indicator that appears at the top of every onboarding
/// screen. Intentionally minimal — no labels, no percent, no animation
/// fanfare. The user can already count dots; explicitly numbering them
/// reads as a chore rather than a milestone.
struct OnboardingProgressBar: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: LuminaSpacing.xs) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(fill(for: index))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == current ? 1.25 : 1.0)
                    .animation(.smooth(duration: 0.2), value: current)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Step \(current + 1) of \(total)")
    }

    private func fill(for index: Int) -> Color {
        if index == current { return LuminaColors.celestialBlue }
        if index < current { return LuminaColors.inkBlack.opacity(0.4) }
        return LuminaColors.inkBlack.opacity(0.15)
    }
}

#Preview {
    VStack(spacing: LuminaSpacing.lg) {
        OnboardingProgressBar(total: 8, current: 0)
        OnboardingProgressBar(total: 8, current: 2)
        OnboardingProgressBar(total: 8, current: 5)
        OnboardingProgressBar(total: 8, current: 7)
    }
    .padding(LuminaSpacing.lg)
    .background(LuminaColors.parchment)
}
