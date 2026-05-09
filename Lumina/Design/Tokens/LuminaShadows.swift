import SwiftUI

/// Three semantic elevation levels. Shadows in this app stay quiet — we are
/// editorial, not flashy. Anything heavier than `.elevated` is a brand
/// violation.
///
/// Use via `.luminaShadow(.card)` rather than calling `.shadow(...)`
/// directly so reviewers can see intent at a glance.
enum LuminaShadow {
    /// Faint outline — used for subtle separation between adjacent surfaces.
    case subtle
    /// Standard card shadow — used by `LuminaCard` and most content cards.
    case card
    /// Heaviest brand-allowed shadow — sheets, modals, the chart-wheel hero.
    case elevated
}

extension View {
    /// Applies the shadow tokens. Honors `colorScheme` so dark mode reads
    /// the shadow against the right background.
    func luminaShadow(_ token: LuminaShadow) -> some View {
        modifier(LuminaShadowModifier(token: token))
    }
}

private struct LuminaShadowModifier: ViewModifier {
    let token: LuminaShadow

    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        switch token {
        case .subtle:
            content.shadow(color: shadowColor(opacity: 0.04), radius: 2, x: 0, y: 1)
        case .card:
            content.shadow(color: shadowColor(opacity: 0.08), radius: 8, x: 0, y: 2)
        case .elevated:
            content.shadow(color: shadowColor(opacity: 0.14), radius: 22, x: 0, y: 8)
        }
    }

    private func shadowColor(opacity: Double) -> Color {
        // Light mode → ink shadow against parchment; dark mode shadows are
        // imperceptible on a dark background, so we keep them as-is and
        // rely on the surface stroke instead.
        scheme == .dark ? .clear : LuminaColors.inkBlack.opacity(opacity)
    }
}
