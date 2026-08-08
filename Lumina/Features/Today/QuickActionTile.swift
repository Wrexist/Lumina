import SwiftUI

/// The tile face used by Today's quick-actions row — shared by the tab-jump
/// buttons and the Moments `NavigationLink`, so both keep the row's rhythm.
///
/// Its own view (rather than a helper on `TodayHubView`) because that file
/// sits against SwiftLint's 400-line ceiling, and because the `@ScaledMetric`
/// icon size belongs with the thing it sizes.
struct QuickActionTile: View {
    let title: String
    let systemImage: String

    @ScaledMetric private var iconSize: CGFloat = 28

    var body: some View {
        LuminaCard(padding: LuminaSpacing.md) {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: iconSize, weight: .light))
                    .foregroundStyle(LuminaColors.celestialBlue)
                Text(title).font(LuminaTypography.body)
            }
            .frame(width: 140, alignment: .leading)
        }
    }
}

#Preview {
    HStack {
        QuickActionTile(title: "Your chart", systemImage: "circle.dotted")
        QuickActionTile(title: "Moments", systemImage: "sparkles")
    }
    .padding()
}
