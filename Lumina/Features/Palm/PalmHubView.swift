import SwiftUI

/// Phase-6 placeholder. Empty-state path until the Vision + Core ML
/// pipeline lands. Drives "Scan a hand" as the primary CTA.
struct PalmHubView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: LuminaSpacing.lg) {
                LuminaEmptyState(
                    systemImage: "hand.raised",
                    title: "Read your hand",
                    body: "Your phone's camera + on-device AI traces the four major lines. Photos never leave your device.",
                    primaryCTA: LuminaEmptyState.CTA(title: "Scan a hand", action: handleScan),
                    secondaryCTA: LuminaEmptyState.CTA(title: "How this works", action: handleExplain)
                )

                LuminaCard {
                    VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                        HStack(spacing: LuminaSpacing.sm) {
                            LuminaBadge(title: "Plus", tone: .premium)
                            Text("Unlimited scans")
                                .font(LuminaTypography.body)
                        }
                        Text("Free includes one scan a month. Lumina Plus removes the limit and unlocks the deep narration.")
                            .font(LuminaTypography.bodyLight)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                    }
                }
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle("Palm")
    }

    private func handleScan() {
        // TODO(lumina): present PalmCaptureView (Phase 6)
    }

    private func handleExplain() {
        // TODO(lumina): present transparency sheet (Phase 6)
    }
}

#Preview {
    NavigationStack { PalmHubView() }
}
