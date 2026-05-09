import SwiftUI

/// Small inline link that opens a 1–2-sentence explainer sheet for a
/// sensitive field. The clarity charter (`docs/NAVIGATION.md` §1.4)
/// requires every onboarding field that asks for personal information to
/// answer "why are you asking me this?" in one tap.
///
/// Usage:
/// ```swift
/// WhyWeAsk(
///     title: "Why we ask for your birth time",
///     body: "Without time, we can still calculate your sign and planets — only houses are hidden."
/// )
/// ```
struct WhyWeAsk: View {
    let title: String
    let body: String

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
            Haptics.selection.play()
        } label: {
            HStack(spacing: LuminaSpacing.xs) {
                Image(systemName: "info.circle")
                    .font(.caption)
                Text("Why we ask")
                    .font(LuminaTypography.caption)
            }
            .foregroundStyle(LuminaColors.celestialBlue)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Why we ask: \(title)")
        .sheet(isPresented: $isPresented) {
            WhyWeAskSheet(title: title, body: body)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct WhyWeAskSheet: View {
    let title: String
    let body: String

    var body: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.md) {
            Text(title)
                .font(LuminaTypography.heading)
            Text(body)
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
            Spacer()
        }
        .padding(LuminaSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LuminaColors.parchment)
    }
}

#Preview {
    VStack(alignment: .leading) {
        WhyWeAsk(
            title: "Why we ask for your birth time",
            body: "Without time, we can still calculate your sign and planets — only houses are hidden."
        )
    }
    .padding(LuminaSpacing.lg)
    .background(LuminaColors.parchment)
}
