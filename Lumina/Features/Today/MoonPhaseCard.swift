import SwiftUI

/// "Tonight's Moon" — the current lunar phase, illumination, and the nearer of
/// the next new/full moon. Global sky data fetched by `TodayViewModel`'s
/// shared fan-out and passed in, so the card renders in step with the rest of
/// the sky context instead of popping in on its own.
struct MoonPhaseCard: View {
    let phase: MoonPhaseResult
    @Environment(AppRouter.self) private var router
    @State private var showing3D = false
    @ScaledMetric private var glyphSize: CGFloat = 40

    var body: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("TONIGHT'S MOON")
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                HStack(spacing: LuminaSpacing.md) {
                    Image(systemName: MoonPhasePresentation.symbol(for: phase.phase))
                        .font(.system(size: glyphSize, weight: .light))
                        .foregroundStyle(LuminaColors.goldInk)
                    VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                        Text(phase.phase)
                            .font(LuminaTypography.heading)
                        Text(MoonPhasePresentation.illuminationText(phase.illumination))
                            .font(LuminaTypography.body)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                        Text(MoonPhasePresentation.nextEvent(nextNew: phase.nextNewMoon, nextFull: phase.nextFullMoon))
                            .font(LuminaTypography.caption)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                    }
                }
                if let ritual = MoonRitual.prompt(forAngle: phase.angle) {
                    Divider()
                    Text(ritual)
                        .font(LuminaTypography.body)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let cta = MoonRitual.callToAction(forAngle: phase.angle) {
                        LuminaButton(title: cta, variant: .ghost, systemImage: "moon.stars") {
                            jumpToReflect()
                        }
                    }
                }
                LuminaButton(title: "View in 3D", variant: .ghost, systemImage: "sparkles") {
                    show3D()
                }
            }
        }
        .sheet(isPresented: $showing3D) {
            MoonSphereSheetView(phase: phase)
        }
    }

    // MARK: - Methods

    private func jumpToReflect() {
        // Following a ritual prompt into Reflect is the "moon ritual begun"
        // Moment — intention, not just a glance. `unlock` is idempotent and
        // returns true only on the first-ever unlock, so the success haptic
        // fires once (matching every other Moment); repeats get the light tick.
        if MomentsStore.shared.unlock(.firstRitual) {
            Haptics.success.play()
        } else {
            Haptics.light.play()
        }
        router.selectedTab = .reflect
    }

    private func show3D() {
        Haptics.light.play()
        showing3D = true
    }
}
