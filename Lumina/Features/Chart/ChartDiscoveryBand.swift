import SwiftUI

/// Quiet discovery map under the chart wheel: one small dot per placement,
/// filled in muted gold once the user has opened that placement's reading.
/// A map, not a checklist — the dots aren't buttons, nothing counts down,
/// and the only celebration is one line (and a single haptic, once ever)
/// when the whole chart has been met.
///
/// Charts without a birth time have no Ascendant, so the band honestly
/// shows ten dots instead of eleven.
struct ChartDiscoveryBand: View {
    let chart: NatalChart

    @State private var discovery = ChartDiscovery.shared
    @State private var preferences = AppPreferences.shared
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @ScaledMetric private var dotSize: CGFloat = 8

    private var reduceMotion: Bool {
        LuminaMotion.isReduced(system: systemReduceMotion, appOverride: preferences.reduceMotionOverride)
    }

    /// Placements that exist for this chart — the Ascendant only when the
    /// birth time (and therefore `chart.houses`) is known.
    private var keys: [String] {
        if chart.houses == nil {
            return ChartDiscovery.placementKeys.filter { $0 != "Ascendant" }
        }
        return ChartDiscovery.placementKeys
    }

    private var exploredCount: Int {
        discovery.exploredCount(of: keys)
    }

    private var isComplete: Bool {
        exploredCount == keys.count
    }

    var body: some View {
        VStack(spacing: LuminaSpacing.sm) {
            dotsRow
            caption
        }
        .frame(maxWidth: .infinity)
        .animation(reduceMotion ? .none : .smooth, value: exploredCount)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .onChange(of: isComplete, initial: true) { _, complete in
            guard complete, discovery.celebrateCompletionIfNeeded() else { return }
            Haptics.success.play()
        }
    }

    private var dotsRow: some View {
        HStack(spacing: LuminaSpacing.sm) {
            ForEach(keys, id: \.self) { key in
                dot(explored: discovery.isExplored(key))
            }
        }
    }

    private func dot(explored: Bool) -> some View {
        Circle()
            .fill(explored ? LuminaColors.mutedGold : Color.clear)
            .overlay(
                Circle().stroke(
                    explored ? LuminaColors.mutedGold : LuminaColors.mutedGold.opacity(0.35),
                    lineWidth: 1
                )
            )
            .frame(width: dotSize, height: dotSize)
    }

    @ViewBuilder
    private var caption: some View {
        if isComplete {
            Text("You've met your whole chart ✦")
                .font(LuminaTypography.caption)
                .foregroundStyle(LuminaColors.mutedGold)
                .multilineTextAlignment(.center)
        } else {
            Text("You've met \(exploredCount) of \(keys.count) placements — tap any planet to keep exploring.")
                .font(LuminaTypography.caption)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }

    private var accessibilitySummary: String {
        if isComplete {
            return "Chart discovery: you've met your whole chart. All \(keys.count) placements explored."
        }
        return "Chart discovery: \(exploredCount) of \(keys.count) placements explored."
    }
}
