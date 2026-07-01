import SwiftUI

/// Empty state for any list / data view. Always offers a primary CTA that
/// fills the empty state — never a dead end. See `docs/NAVIGATION.md` §4.
struct LuminaEmptyState: View {
    struct CTA {
        let title: String
        let action: () -> Void
    }

    let systemImage: String
    let title: String
    let message: String
    var primaryCTA: CTA?
    var secondaryCTA: CTA?
    @ScaledMetric private var iconSize: CGFloat = 48

    init(
        systemImage: String,
        title: String,
        body: String,
        primaryCTA: CTA? = nil,
        secondaryCTA: CTA? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = body
        self.primaryCTA = primaryCTA
        self.secondaryCTA = secondaryCTA
    }

    var content: some View {
        VStack(spacing: LuminaSpacing.lg) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .light))
                .foregroundStyle(LuminaColors.celestialBlue)
                .accessibilityHidden(true)

            VStack(spacing: LuminaSpacing.sm) {
                Text(title)
                    .font(LuminaTypography.heading)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(LuminaColors.inkBlack)
                Text(message)
                    .font(LuminaTypography.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
            .padding(.horizontal, LuminaSpacing.lg)

            VStack(spacing: LuminaSpacing.sm) {
                if let primaryCTA {
                    LuminaButton(title: primaryCTA.title, variant: .primary, action: primaryCTA.action)
                }
                if let secondaryCTA {
                    LuminaButton(title: secondaryCTA.title, variant: .ghost, action: secondaryCTA.action)
                }
            }
            .padding(.horizontal, LuminaSpacing.lg)
        }
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, LuminaSpacing.xxl)
            .accessibilityElement(children: .contain)
    }
}

#Preview {
    func noop() { }
    return LuminaEmptyState(
        systemImage: "person.2",
        title: "No friends yet",
        body: "Add a friend to compare charts and see what's happening between you.",
        primaryCTA: LuminaEmptyState.CTA(title: "Add someone", action: noop),
        secondaryCTA: LuminaEmptyState.CTA(title: "Maybe later", action: noop)
    )
    .background(LuminaColors.parchment)
}
