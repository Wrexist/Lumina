import SwiftUI

/// A shareable card of today's reading — fresh, real, daily content people
/// screenshot (the category's daily-distribution loop, done premium; see
/// `docs/VIRALITY.md`). Rendered off-screen (`ImageRenderer`) to a portrait
/// image. Honest: the reading is grounded in the day's real transits.
struct DailyReadingShareCard: View {
    let reading: String
    let date: Date

    /// "Wednesday · July 2" — each half is locale-aware (`Date.FormatStyle`
    /// orders day/month per locale); the "·" separator is brand styling.
    private var dateLabel: String {
        let weekday = date.formatted(.dateTime.weekday(.wide))
        let monthDay = date.formatted(.dateTime.month(.wide).day())
        return "\(weekday) · \(monthDay)"
    }

    var body: some View {
        VStack(spacing: LuminaSpacing.xl) {
            VStack(spacing: LuminaSpacing.xs) {
                Text("LUMINA")
                    .font(LuminaTypography.mono)
                    .tracking(6)
                    .foregroundStyle(LuminaColors.goldInk)
                Text(dateLabel.uppercased())
                    .font(LuminaTypography.mono)
                    .tracking(2)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            }
            Text("Today's reading")
                .font(LuminaTypography.display)
                .foregroundStyle(LuminaColors.inkBlack)
            Text(reading)
                .font(LuminaTypography.heading)
                .foregroundStyle(LuminaColors.inkBlack)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text("Grounded in today's real sky.")
                .font(LuminaTypography.bodyLight)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
        }
        .padding(LuminaSpacing.xxl)
        .frame(width: 600, height: 800)
        .background(LuminaColors.parchment)
    }
}
