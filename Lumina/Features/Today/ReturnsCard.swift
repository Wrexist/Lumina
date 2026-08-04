import SwiftUI

/// "A major return is coming" — a Jupiter or Saturn return, rendered as the
/// highlighted first row of the "Ahead" card (`WhatsComingCard`) rather than
/// a card of its own. The caller passes only returns that are actually
/// imminent (within the next year), so it stays high-signal and never
/// clutters Today the rest of the time. Honest, never faked.
struct ReturnsCard: View {
    let imminent: [ReturnEvent]

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // Locale-aware month/year ordering (e.g. "July 2026" vs "juillet 2026").
        formatter.setLocalizedDateFormatFromTemplate("MMMMyyyy")
        return formatter
    }()

    var body: some View {
        HStack(alignment: .top, spacing: LuminaSpacing.md) {
            Image(systemName: "sparkles")
                .foregroundStyle(LuminaColors.goldInk)
            VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                GlossaryLink(term: "Saturn return") {
                    Text("A MAJOR RETURN IS COMING")
                }
                .font(LuminaTypography.mono)
                .tracking(1.4)
                ForEach(imminent) { event in
                    Text(ReturnPhrasing.line(for: event, formatter: Self.monthFormatter))
                        .font(LuminaTypography.body)
                        .foregroundStyle(LuminaColors.inkBlack)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Text("A return closes one cycle and opens the next — a natural checkpoint, not a verdict.")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            }
        }
    }
}
