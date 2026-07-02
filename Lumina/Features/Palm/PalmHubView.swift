import SwiftUI

/// Phase-6 placeholder. The capture pipeline (Vision + Core ML
/// segmentation) lands once the custom palm U-Net model trained on
/// PolyU/CASIA data is available — see TASK.md "Blockers". Until then
/// the tab ships a real transparency story and a clear "coming soon"
/// affordance so users understand what we're building.
struct PalmHubView: View {
    @State private var transparencyPresented = false
    /// Persisted so "Notify me" stays confirmed across launches — the
    /// OneSignal tag is set once and the button swaps to a static
    /// "you're on the list" state instead of staying tappable forever.
    @AppStorage("palmWaitlistJoined") private var waitlistJoined = false

    var body: some View {
        ScrollView {
            VStack(spacing: LuminaSpacing.lg) {
                LuminaEmptyState(
                    systemImage: "hand.raised",
                    title: "Read your hand",
                    body: "Your phone's camera + on-device AI traces the four major lines. Photos never leave your device.",
                    primaryCTA: LuminaEmptyState.CTA(title: "How this works", action: presentTransparency),
                    secondaryCTA: waitlistJoined
                        ? nil
                        : LuminaEmptyState.CTA(title: "Notify me when it ships", action: handleNotifyMe)
                )
                if waitlistJoined {
                    waitlistConfirmation
                }
                howWereBuildingItCard
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

    /// Replaces the "Notify me" button once tapped — a confirmation, not a
    /// control, so there's nothing left to re-tap.
    private var waitlistConfirmation: some View {
        Text("You're on the list ✓")
            .font(LuminaTypography.body)
            .foregroundStyle(LuminaColors.celestialBlue)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("You're on the list")
    }

    /// The one honest status card: why palm scanning hasn't shipped yet
    /// (fairness first) and what makes Lumina's approach different.
    private var howWereBuildingItCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                HStack(spacing: LuminaSpacing.sm) {
                    LuminaBadge(title: "Soon", tone: .neutral)
                    Text("How we're building it")
                        .font(LuminaTypography.heading)
                }
                Text("We're making sure the on-device line tracing works fairly across every "
                    + "skin tone before we ship it — that's the part we won't rush. Every other "
                    + "major app in this category overlays a generic illustration on top of your "
                    + "palm and writes a generic reading. Lumina actually traces your lines with "
                    + "an on-device model trained on real palm images.")
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
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
        waitlistJoined = true
        Haptics.success.play()
    }
}

#Preview {
    NavigationStack { PalmHubView() }
}
