import SwiftUI

/// "Tonight's Moon" — the current lunar phase, illumination, and the nearer of
/// the next new/full moon. Global sky data (needs no birth chart), so it loads
/// itself and stays quiet on failure rather than blocking the Today tab.
struct MoonPhaseCard: View {
    @Environment(AppRouter.self) private var router
    @State private var ephemeris = EphemerisService()
    @State private var phase: MoonPhaseResult?
    @State private var showing3D = false
    @ScaledMetric private var glyphSize: CGFloat = 40

    var body: some View {
        Group {
            if let phase {
                loaded(phase)
            }
        }
        .task { await load() }
        .sheet(isPresented: $showing3D) {
            if let phase {
                MoonSphereSheetView(phase: phase)
            }
        }
    }

    // MARK: - View building blocks

    private func loaded(_ moon: MoonPhaseResult) -> some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("TONIGHT'S MOON")
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                HStack(spacing: LuminaSpacing.md) {
                    Image(systemName: MoonPhasePresentation.symbol(for: moon.phase))
                        .font(.system(size: glyphSize, weight: .light))
                        .foregroundStyle(LuminaColors.mutedGold)
                    VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                        Text(moon.phase)
                            .font(LuminaTypography.heading)
                        Text(MoonPhasePresentation.illuminationText(moon.illumination))
                            .font(LuminaTypography.body)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                        Text(MoonPhasePresentation.nextEvent(nextNew: moon.nextNewMoon, nextFull: moon.nextFullMoon))
                            .font(LuminaTypography.caption)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                    }
                }
                if let ritual = MoonRitual.prompt(forAngle: moon.angle) {
                    Divider()
                    Text(ritual)
                        .font(LuminaTypography.body)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let cta = MoonRitual.callToAction(forAngle: moon.angle) {
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
    }

    // MARK: - Methods

    private func jumpToReflect() {
        Haptics.light.play()
        router.selectedTab = .reflect
    }

    private func show3D() {
        Haptics.light.play()
        showing3D = true
    }

    private func load() async {
        do {
            phase = try await ephemeris.moonPhase()
        } catch {
            #if DEBUG
            phase = Self.sample
            #else
            phase = nil
            #endif
        }
    }

    #if DEBUG
    /// Dev-only stand-in so previews and no-backend builds show the card.
    private static let sample = MoonPhaseResult(
        calculatedAt: .now,
        at: .now,
        angle: 236,
        phase: "Waning Gibbous",
        illumination: 0.78,
        nextNewMoon: .now.addingTimeInterval(86_400 * 12),
        nextFullMoon: .now.addingTimeInterval(86_400 * 24)
    )
    #endif
}
