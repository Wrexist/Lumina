import SwiftUI

/// "Why these?" — shows the exact transit data behind Today's reading: which
/// planet, aspecting which natal point, by how much, and whether it's
/// building or separating. No competitor exposes its work like this; it's the
/// "we're real, here's the proof" brand made tangible (COMPETITIVE-ANALYSIS
/// gap G7). Pure display over the already-computed transits.
struct TodayTransparencySheet: View {
    let transits: [TransitReading]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                    Text("Today's lines come from where the planets actually are right now, measured against your birth chart — not a generic horoscope shared with everyone.")
                        .font(LuminaTypography.body)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.8))
                    LuminaCard {
                        VStack(alignment: .leading, spacing: LuminaSpacing.md) {
                            if transits.isEmpty {
                                Text("A quiet sky — nothing significant is aspecting your chart right now.")
                                    .font(LuminaTypography.body)
                                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                            } else {
                                ForEach(Array(transits.prefix(8))) { transit in
                                    transitRow(transit)
                                }
                            }
                        }
                    }
                }
                .padding(LuminaSpacing.lg)
            }
            .background(LuminaColors.parchment)
            .navigationTitle("Why these?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func transitRow(_ transit: TransitReading) -> some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
            Text(TransitPhrasing.sentence(for: transit))
                .font(LuminaTypography.body)
            Text(detail(for: transit))
                .font(LuminaTypography.mono)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func detail(for transit: TransitReading) -> String {
        let phase = transit.applying ? "applying" : "separating"
        let orb = String(format: "%.1f° orb", transit.orb)
        return "transiting \(transit.transiting) \(TransitPhrasing.aspectWord(transit.type)) "
            + "natal \(transit.natal) · \(orb) · \(phase)"
    }
}
