import SwiftUI

/// Rising-sign (ascendant) detail: sign, degree, and a grounded reading of the
/// ascendant (`AscendantInterpreter`). Mirrors `PlanetDetailSheet` for the one
/// Big-3 placement that isn't a planet (so it carries no house or retrograde).
struct AscendantDetailSheet: View {
    let ascendant: Double

    @Environment(\.dismiss) private var dismiss
    @ScaledMetric private var glyphSize: CGFloat = 64

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                    header
                    factsCard
                    interpretationCard
                }
                .padding(LuminaSpacing.lg)
            }
            .background(LuminaColors.parchment)
            .navigationTitle("Rising")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear(perform: recordDiscovery)
    }

    /// Chart discovery: opening the ascendant reading counts as meeting it.
    /// One success haptic marks a first meeting — once, ever.
    private func recordDiscovery() {
        if ChartDiscovery.shared.markExplored("Ascendant") {
            Haptics.success.play()
        }
    }

    private var sign: String {
        ChartGlyphs.sign(forLongitude: ascendant)
    }

    private var header: some View {
        HStack(spacing: LuminaSpacing.md) {
            Text(ChartGlyphs.signGlyph(sign))
                .font(.system(size: glyphSize))
                .foregroundStyle(LuminaColors.goldInk)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                Text("\(sign) Rising")
                    .font(LuminaTypography.heading)
                Text(degreeString)
                    .font(LuminaTypography.mono)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            }
            Spacer()
        }
    }

    private var factsCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                row("Sign", value: sign)
                row("Degree", value: degreeString)
            }
        }
    }

    private var interpretationCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("What this means")
                    .font(LuminaTypography.heading)
                Text(AscendantInterpreter.interpretation(longitude: ascendant))
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.8))
            }
        }
    }

    private var degreeString: String {
        let degrees = Int(ascendant.truncatingRemainder(dividingBy: 30))
        let minutes = Int((ascendant.truncatingRemainder(dividingBy: 1)) * 60)
        return "\(degrees)° \(minutes)′"
    }

    private func row(_ key: String, value: String) -> some View {
        HStack {
            Text(key.uppercased())
                .font(LuminaTypography.mono)
                .tracking(1.2)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            Spacer()
            Text(value)
                .font(LuminaTypography.body)
        }
    }
}
