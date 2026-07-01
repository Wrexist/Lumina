import SwiftUI

/// Brand card with parchment surface, subtle shadow, and (where the OS
/// supports it) the iOS 26 Liquid Glass background effect for elevated
/// surfaces. Most content sits inside one of these.
struct LuminaCard<Content: View>: View {
    enum Surface {
        case parchment
        case glass
        case midnight
    }

    var surface: Surface = .parchment
    var padding: CGFloat = LuminaSpacing.md
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(surfaceBackground)
            .foregroundStyle(foreground)
            .luminaCornerRadius(LuminaRadii.md)
            .overlay(highlight)
            .overlay(border)
            .luminaShadow(.card)
    }

    /// A very faint "lit from above" sheen so cards read as slightly raised
    /// glass rather than flat outlines. Clipped to the card shape and kept
    /// low-opacity so it never darkens the parchment surface.
    @ViewBuilder
    private var highlight: some View {
        RoundedRectangle(cornerRadius: LuminaRadii.md, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [LuminaColors.parchment.opacity(0.06), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var surfaceBackground: some View {
        switch surface {
        case .parchment:
            LuminaColors.parchment
        case .glass:
            // TODO(lumina): swap to the iOS 26 native Liquid Glass API
            // (`.glassEffect`) once it can be verified on a Mac — the brand
            // pillar wants real glass, not a material. `.thinMaterial` is the
            // interim frosted fallback. See docs/AUDIT-2026-06-03.md R6.
            Rectangle()
                .fill(.thinMaterial)
        case .midnight:
            LuminaColors.midnight
        }
    }

    private var foreground: Color {
        surface == .midnight ? LuminaColors.parchment : LuminaColors.inkBlack
    }

    @ViewBuilder
    private var border: some View {
        RoundedRectangle(cornerRadius: LuminaRadii.md, style: .continuous)
            .stroke(LuminaColors.inkBlack.opacity(0.08), lineWidth: 1)
    }
}

#Preview("Surfaces") {
    VStack(spacing: LuminaSpacing.md) {
        LuminaCard {
            Text("Parchment surface — used for body content cards.")
                .font(LuminaTypography.body)
        }
        LuminaCard(surface: .glass) {
            Text("Glass surface — used for elevated overlays.")
                .font(LuminaTypography.body)
        }
        LuminaCard(surface: .midnight) {
            Text("Midnight surface — chart wheel and hero spreads.")
                .font(LuminaTypography.body)
        }
    }
    .padding(LuminaSpacing.lg)
    .background(LuminaColors.parchment)
}
