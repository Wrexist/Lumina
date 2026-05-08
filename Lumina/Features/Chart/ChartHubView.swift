import SwiftUI

/// Phase-4 placeholder. Eventually hosts the chart-wheel `Canvas`, planet
/// detail sheets, and a Western/Human-Design toggle. For now we render the
/// full empty layout so the rest of the shell can be exercised.
struct ChartHubView: View {
    enum ChartMode: Hashable, CaseIterable {
        case astrology
        case humanDesign
    }

    @State private var system: HouseSystem = .placidus
    @State private var mode: ChartMode = .astrology

    var body: some View {
        ScrollView {
            VStack(spacing: LuminaSpacing.lg) {
                modePicker
                placeholderWheel
                housePicker
                LuminaButton(title: "Tap a planet to learn more", variant: .secondary, systemImage: "hand.tap") {
                    // TODO(lumina): present sheet with first-tap hint
                }
                LuminaCard {
                    Text("Once your chart math finishes, this is where the planet, house, and aspect summaries live.")
                        .font(LuminaTypography.body)
                }
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle("Chart")
    }

    private var modePicker: some View {
        LuminaSegmentedControl(
            options: [
                (ChartMode.astrology, "Astrology"),
                (ChartMode.humanDesign, "Human Design"),
            ],
            selection: $mode
        )
    }

    private var housePicker: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
            Text("HOUSE SYSTEM")
                .font(LuminaTypography.mono)
                .tracking(1.4)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            LuminaSegmentedControl(
                options: [
                    (HouseSystem.placidus, "Placidus"),
                    (HouseSystem.wholeSign, "Whole-sign"),
                    (HouseSystem.sidereal, "Sidereal"),
                ],
                selection: $system
            )
        }
    }

    private var placeholderWheel: some View {
        ZStack {
            Circle().stroke(LuminaColors.inkBlack.opacity(0.15), lineWidth: 1)
            Circle().stroke(LuminaColors.inkBlack.opacity(0.08), lineWidth: 1).scaleEffect(0.78)
            Circle().stroke(LuminaColors.inkBlack.opacity(0.06), lineWidth: 1).scaleEffect(0.55)
            VStack(spacing: LuminaSpacing.xs) {
                Text("Chart wheel").font(LuminaTypography.heading)
                Text("Phase 4 of the roadmap")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.vertical, LuminaSpacing.md)
    }
}

#Preview {
    NavigationStack {
        ChartHubView().environment(GlossaryStore.shared)
    }
}
