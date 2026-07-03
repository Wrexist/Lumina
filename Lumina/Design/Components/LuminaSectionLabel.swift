import SwiftUI

/// SCREAMING-MONO kicker that labels a section (e.g. "QUESTION 1 OF 3",
/// "TONIGHT", "YOUR CHART"). Bakes the uppercase monospaced tracking treatment
/// that is currently copy-pasted inline in ~20 places across the app so those
/// sites can collapse to a single `LuminaSectionLabel("…")` call. Uses
/// `inkBlack.opacity(0.7)` (not 0.6) so the small mono text clears contrast.
///
/// Adoption across existing screens happens in a later sweep — this file just
/// ships the reusable component and its preview.
struct LuminaSectionLabel: View {
    private let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(LuminaTypography.mono)
            .tracking(1.4)
            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            .textCase(.uppercase)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: LuminaSpacing.md) {
        LuminaSectionLabel("Question 1 of 3")
        LuminaSectionLabel("Tonight")
        LuminaSectionLabel("Your chart")
    }
    .padding(LuminaSpacing.lg)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(LuminaColors.parchment)
}
