import SwiftUI

/// Phase-6 placeholder. The capture pipeline (Vision + Core ML
/// segmentation) lands once the custom palm U-Net model trained on
/// PolyU/CASIA data is available — see TASK.md "Blockers". Until then
/// the tab ships a real transparency story and a clear "coming soon"
/// affordance so users understand what we're building.
struct PalmHubView: View {
    @State private var transparencyPresented = false

    var body: some View {
        ScrollView {
            VStack(spacing: LuminaSpacing.lg) {
                LuminaEmptyState(
                    systemImage: "hand.raised",
                    title: "Read your hand",
                    body: "Your phone's camera + on-device AI traces the four major lines. Photos never leave your device.",
                    primaryCTA: LuminaEmptyState.CTA(title: "How this works", action: presentTransparency),
                    secondaryCTA: LuminaEmptyState.CTA(title: "Notify me when it ships", action: handleNotifyMe)
                )
                differentiatorCard
                premiumCard
                blockerNote
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle("Palm")
        .sheet(isPresented: $transparencyPresented) {
            PalmTransparencyView()
        }
    }

    // MARK: - View building blocks

    private var differentiatorCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                HStack(spacing: LuminaSpacing.sm) {
                    Image(systemName: "wand.and.sparkles")
                        .foregroundStyle(LuminaColors.celestialBlue)
                    Text("Why ours is different")
                        .font(LuminaTypography.heading)
                }
                Text("Every other major app in this category overlays a generic illustration on top of "
                    + "your palm and writes a generic reading. Lumina actually traces your lines with an "
                    + "on-device model trained on real palm images.")
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
            }
        }
    }

    private var premiumCard: some View {
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

    private var blockerNote: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                HStack(spacing: LuminaSpacing.sm) {
                    LuminaBadge(title: "Soon", tone: .neutral)
                    Text("Where we are")
                        .font(LuminaTypography.body)
                }
                Text("Palm scanning is coming soon. We're making sure the on-device line tracing works "
                    + "fairly across every skin tone before we ship it — that's the part we won't rush.")
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
        }
    }

    // MARK: - Methods

    private func presentTransparency() {
        Haptics.light.play()
        transparencyPresented = true
    }

    private func handleNotifyMe() {
        PushNotificationManager.setTag(key: "palm_waitlist", value: "true")
        Haptics.medium.play()
    }
}

#Preview {
    NavigationStack { PalmHubView() }
}
