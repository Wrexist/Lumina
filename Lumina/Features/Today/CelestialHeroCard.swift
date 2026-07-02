import SwiftUI

/// The signature immersive band at the top of the Today tab: a starfield-lit
/// midnight sky carrying the date and "Your sky today" in the editorial serif.
/// It renders identically in every Today state (loading, error, ready), so the
/// screen never feels flat or broken — the static frame (gradient + gold stars
/// + serif title) is composed to look good in the `ImageRenderer` screenshot
/// harness without relying on motion.
struct CelestialHeroCard: View {
    let date: Date
    var subtitle: String = "Your sky today"

    /// Fixed band height that still scales with Dynamic Type.
    @ScaledMetric private var height: CGFloat = 210

    /// When false, the background is static — used by previews / screenshots.
    var showsMotion: Bool = true

    var body: some View {
        LuminaCelestialBackground(showsMotion: showsMotion)
            .frame(height: height)
            .overlay(alignment: .bottomLeading) { foreground }
            .luminaCornerRadius(LuminaRadii.lg)
            .luminaShadow(.elevated)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(dateLabel). \(subtitle).")
    }

    private var foreground: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
            HStack(spacing: LuminaSpacing.sm) {
                Text(dateLabel.uppercased())
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.parchment.opacity(0.7))
                Image(systemName: "sparkles")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.mutedGold)
            }
            Text(subtitle)
                .font(LuminaTypography.display)
                .foregroundStyle(LuminaColors.parchment)
        }
        .padding(LuminaSpacing.lg)
    }

    /// "Wednesday · Jul 2" — each half is locale-aware (`Date.FormatStyle`
    /// orders day/month per locale); the "·" separator is brand styling.
    private var dateLabel: String {
        let weekday = date.formatted(.dateTime.weekday(.wide))
        let monthDay = date.formatted(.dateTime.month(.abbreviated).day())
        return "\(weekday) · \(monthDay)"
    }
}

#Preview("Celestial Hero") {
    CelestialHeroCard(date: .now, showsMotion: false)
        .padding(LuminaSpacing.lg)
        .background(LuminaColors.parchment)
}
