import SwiftUI

/// Tiny pill used to flag premium gates, beta features, and "new" surfaces.
/// Placed inline next to a title or in the leading edge of a row.
struct LuminaBadge: View {
    enum Tone {
        case premium
        case beta
        case fresh
        case neutral
    }

    let title: String
    var tone: Tone = .neutral

    var body: some View {
        Text(title.uppercased())
            .font(LuminaTypography.mono)
            .tracking(1.4)
            .foregroundStyle(foreground)
            .padding(.horizontal, LuminaSpacing.sm)
            .padding(.vertical, LuminaSpacing.xs)
            .background(background)
            .clipShape(.capsule)
    }

    private var background: Color {
        switch tone {
        case .premium: LuminaColors.mutedGold
        case .beta: LuminaColors.celestialBlue
        case .fresh: LuminaColors.blush
        case .neutral: LuminaColors.inkBlack.opacity(0.08)
        }
    }

    private var foreground: Color {
        switch tone {
        case .premium, .beta: LuminaColors.parchment
        case .fresh, .neutral: LuminaColors.inkBlack
        }
    }
}

#Preview {
    HStack(spacing: LuminaSpacing.sm) {
        LuminaBadge(title: "Plus", tone: .premium)
        LuminaBadge(title: "Beta", tone: .beta)
        LuminaBadge(title: "New", tone: .fresh)
        LuminaBadge(title: "Coming soon", tone: .neutral)
    }
    .padding(LuminaSpacing.lg)
    .background(LuminaColors.parchment)
}
