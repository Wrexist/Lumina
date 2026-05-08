import SwiftUI

/// Brand button. Use the four cases for everything — a feature should never
/// invent a fifth style. See `docs/NAVIGATION.md` §5: every screen has
/// exactly one `.primary` button.
///
/// A view renders a `LuminaButton` directly; we don't expose a separate
/// `ButtonStyle` because the text + accessory + loading state all live here.
struct LuminaButton: View {
    enum Variant {
        case primary
        case secondary
        case ghost
        case destructive
    }

    let title: String
    var variant: Variant = .primary
    var systemImage: String?
    var isLoading = false
    var isEnabled = true
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            ZStack {
                contents.opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(foreground)
                }
            }
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .padding(.horizontal, LuminaSpacing.lg)
            .background(background)
            .foregroundStyle(foreground)
            .overlay(border)
            .clipShape(.rect(cornerRadius: LuminaSpacing.md))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.45)
        .animation(reduceMotion ? .none : .smooth(duration: 0.2), value: isLoading)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isEnabled ? [.isButton] : [.isButton, .notEnabled])
    }

    private var contents: some View {
        HStack(spacing: LuminaSpacing.sm) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title)
                .font(LuminaTypography.body)
        }
    }

    private var minHeight: CGFloat {
        switch variant {
        case .primary, .destructive: 56
        case .secondary, .ghost: 44
        }
    }

    private var background: Color {
        switch variant {
        case .primary: LuminaColors.celestialBlue
        case .destructive: LuminaColors.inkBlack
        case .secondary, .ghost: .clear
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary, .destructive: LuminaColors.parchment
        case .secondary, .ghost: LuminaColors.inkBlack
        }
    }

    @ViewBuilder
    private var border: some View {
        if variant == .secondary {
            RoundedRectangle(cornerRadius: LuminaSpacing.md, style: .continuous)
                .stroke(LuminaColors.inkBlack.opacity(0.2), lineWidth: 1)
        } else {
            EmptyView()
        }
    }
}

#Preview("Variants") {
    VStack(spacing: LuminaSpacing.md) {
        LuminaButton(title: "Read today", variant: .primary) { }
        LuminaButton(title: "See chart", variant: .secondary, systemImage: "circle.dotted") { }
        LuminaButton(title: "Maybe later", variant: .ghost) { }
        LuminaButton(title: "Delete entry", variant: .destructive) { }
        LuminaButton(title: "Loading…", variant: .primary, isLoading: true) { }
    }
    .padding(LuminaSpacing.lg)
    .background(LuminaColors.parchment)
}
