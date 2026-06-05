import SwiftUI

/// "Tonight's Moon" — the current lunar phase, illumination, and the nearer of
/// the next new/full moon. Global sky data (needs no birth chart), so it loads
/// itself and stays quiet on failure rather than blocking the Today tab.
struct MoonPhaseCard: View {
    @State private var ephemeris = EphemerisService()
    @State private var phase: MoonPhaseResult?
    @ScaledMetric private var glyphSize: CGFloat = 40

    var body: some View {
        Group {
            if let phase {
                loaded(phase)
            }
        }
        .task { await load() }
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
            }
        }
    }

    // MARK: - Methods

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
