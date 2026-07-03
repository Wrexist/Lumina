import SwiftUI

/// The top-right "xmark" dismiss affordance used by sheets and overlays that
/// don't have a navigation "Done" button. Standardizes the glyph, weight, and
/// muted tint (and the "Dismiss" VoiceOver label) so each surface stops
/// hand-rolling its own `Image("xmark")` button.
///
/// Adoption across existing sheets happens in a later sweep — this file just
/// ships the reusable component and its preview.
struct LuminaDismissButton: View {
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(LuminaTypography.caption)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                .frame(width: LuminaSpacing.lg, height: LuminaSpacing.lg)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Dismiss")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    ZStack(alignment: .topTrailing) {
        LuminaColors.parchment
        LuminaDismissButton { }
            .padding(LuminaSpacing.md)
    }
    .frame(width: 240, height: 160)
}
