import SwiftUI

/// "Your current chapter" — the secondary-progressed Moon (and Sun) sign, the
/// season you're living now. Data arrives from `TodayViewModel`'s shared
/// fan-out; the hub shows the card prominently only around a progressed-Moon
/// sign change (`ProgressedChapter.isNearCusp`) and demotes it below the
/// quick actions the rest of the time. Honest, never faked.
struct ProgressedChapterCard: View {
    let result: ProgressionsResult

    var body: some View {
        if let moonLine = ProgressedChapter.moonLine(for: result) {
            loaded(moonLine, sunLine: ProgressedChapter.sunLine(for: result))
        }
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
}
