import SwiftUI

/// A transient, dark "snackbar" banner with a single action — the brand's
/// recoverable-delete affordance (swipe / long-press to remove → "Undo").
/// Dark `inkBlack` on the parchment app so it reads as a temporary system
/// message. Callers overlay it at the bottom while a deletion is pending and
/// drive the auto-commit timer with a `.task(id:)` (see `PeopleHubView`).
struct LuminaSnackbarView: View {
    let message: String
    let actionTitle: String
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: LuminaSpacing.md) {
            Text(message)
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.parchment)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(actionTitle, action: onAction)
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.mutedGold)
        }
        .padding(LuminaSpacing.md)
        .background(LuminaColors.inkBlack)
        .luminaCornerRadius(LuminaRadii.md)
        .luminaShadow(.elevated)
        .padding(.horizontal, LuminaSpacing.lg)
        .accessibilityElement(children: .combine)
    }
}
