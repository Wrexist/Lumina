import SwiftUI

/// Expandable card explaining the five aspect line styles drawn in
/// `ChartWheelView`. Defaults collapsed so the wheel reads cleanly on
/// first open; the user can pop it open from the chart tab to decode
/// the colors.
struct AspectLegend: View {
    @State private var expanded = false
    @State private var preferences = AppPreferences.shared
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    /// Effective Reduce Motion — the OS setting or the in-app override.
    private var reduceMotion: Bool {
        LuminaMotion.isReduced(system: systemReduceMotion, appOverride: preferences.reduceMotionOverride)
    }

    var body: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                header
                if expanded {
                    Divider()
                    ForEach(AspectType.allCases, id: \.self) { type in
                        row(for: type)
                    }
                }
            }
        }
    }

    // MARK: - View building blocks

    private var header: some View {
        Button {
            if reduceMotion {
                expanded.toggle()
            } else {
                withAnimation(.smooth(duration: 0.2)) { expanded.toggle() }
            }
            Haptics.selection.play()
        } label: {
            HStack {
                Text("Aspects")
                    .font(LuminaTypography.heading)
                Spacer()
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(expanded ? "Collapse aspects legend" : "Expand aspects legend")
    }

    private func row(for type: AspectType) -> some View {
        HStack(alignment: .center, spacing: LuminaSpacing.md) {
            swatch(color: color(for: type), width: lineWidth(for: type))
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName(for: type))
                    .font(LuminaTypography.body)
                Text(meaning(for: type))
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
            Spacer()
            Text("\(degrees(for: type))°")
                .font(LuminaTypography.mono)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
        }
    }

    private func swatch(color: Color, width: CGFloat) -> some View {
        Capsule()
            .fill(color)
            .frame(height: width)
    }

    // MARK: - Methods

    private func color(for type: AspectType) -> Color {
        switch type {
        // Must track `ChartWheelView.aspectColor` — a legend swatch that
        // doesn't match the line it explains is worse than no legend. The
        // hard-aspect swatch used to be `blush`, which rendered as a blank
        // capsule on parchment.
        case .conjunction: LuminaColors.mutedGold.opacity(0.8)
        case .sextile, .trine: LuminaColors.celestialBlue.opacity(0.6)
        case .square, .opposition: LuminaColors.error.opacity(0.7)
        }
    }

    private func lineWidth(for type: AspectType) -> CGFloat {
        switch type {
        case .conjunction, .opposition: 2.4
        case .square, .trine: 1.8
        case .sextile: 1.2
        }
    }

    private func displayName(for type: AspectType) -> String {
        switch type {
        case .conjunction: "Conjunction"
        case .sextile: "Sextile"
        case .square: "Square"
        case .trine: "Trine"
        case .opposition: "Opposition"
        }
    }

    private func degrees(for type: AspectType) -> Int {
        switch type {
        case .conjunction: 0
        case .sextile: 60
        case .square: 90
        case .trine: 120
        case .opposition: 180
        }
    }

    private func meaning(for type: AspectType) -> String {
        switch type {
        case .conjunction: "Two planets fused — they speak with one voice."
        case .sextile: "Light, productive — easy to work with."
        case .square: "Friction — the place asking for adjustment."
        case .trine: "Flow — talents that come naturally."
        case .opposition: "Polarity — two pulls that need both ends."
        }
    }
}

#Preview {
    AspectLegend()
        .padding(LuminaSpacing.lg)
        .background(LuminaColors.parchment)
}
