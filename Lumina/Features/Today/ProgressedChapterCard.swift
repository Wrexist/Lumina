import SwiftUI

/// "Your current chapter" — the secondary-progressed Moon (and Sun) sign, the
/// season you're living now. Global to the user's chart, so it loads itself and
/// stays quiet on failure rather than blocking Today. Honest, never faked.
struct ProgressedChapterCard: View {
    @State private var ephemeris = EphemerisService()
    @State private var result: ProgressionsResult?

    var body: some View {
        Group {
            if let result, let moonLine = ProgressedChapter.moonLine(for: result) {
                loaded(moonLine, sunLine: ProgressedChapter.sunLine(for: result))
            }
        }
        .task { await load() }
    }

    private func loaded(_ moonLine: String, sunLine: String?) -> some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("YOUR CURRENT CHAPTER")
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                Text(moonLine)
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let sunLine {
                    Text(sunLine)
                        .font(LuminaTypography.caption)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                }
            }
        }
    }

    private func load() async {
        guard let birth = UserBirthDataStore.userDefaults.load() else { return }
        do {
            result = try await ephemeris.progressions(for: birth)
        } catch {
            #if DEBUG
            result = Self.sample
            #else
            result = nil
            #endif
        }
    }

    #if DEBUG
    private static let sample = ProgressionsResult(
        calculatedAt: .now,
        on: .now,
        progressedAt: .now,
        planets: [
            NatalChart.PlanetPosition(planet: "Sun", longitude: 130, latitude: 0, isRetrograde: false),
            NatalChart.PlanetPosition(planet: "Moon", longitude: 215, latitude: 0, isRetrograde: false),
        ]
    )
    #endif
}
