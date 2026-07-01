import SwiftUI

/// Error state mapped from a `LuminaError`. Offers retry by default and a
/// secondary "Close" / "Not now" path. Never shows error codes — see
/// `docs/NAVIGATION.md` §1.6.
struct LuminaErrorState: View {
    let error: LuminaError
    var onRetry: (() -> Void)?
    var onCancel: (() -> Void)?
    @ScaledMetric private var iconSize: CGFloat = 44

    var body: some View {
        VStack(spacing: LuminaSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .light))
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                .accessibilityHidden(true)

            VStack(spacing: LuminaSpacing.sm) {
                Text(error.userTitle)
                    .font(LuminaTypography.heading)
                    .multilineTextAlignment(.center)
                Text(error.userBody)
                    .font(LuminaTypography.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
            .padding(.horizontal, LuminaSpacing.lg)

            VStack(spacing: LuminaSpacing.sm) {
                if let onRetry {
                    LuminaButton(title: error.recoveryActionTitle, variant: .primary, action: onRetry)
                }
                if let onCancel {
                    LuminaButton(title: "Not now", variant: .ghost, action: onCancel)
                }
            }
            .padding(.horizontal, LuminaSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, LuminaSpacing.xxl)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(error.userTitle). \(error.userBody)")
    }

    private var icon: String {
        switch error {
        case .offline: "wifi.slash"
        case .server: "exclamationmark.bubble"
        case .timeout: "hourglass"
        case .notSignedIn: "person.crop.circle.badge.questionmark"
        case .subscriptionRequired: "sparkles"
        case .permissionDenied: "lock"
        case .missingConfiguration: "moon.stars"
        case .unknown: "questionmark.diamond"
        }
    }
}

#Preview {
    func noop() { }
    return LuminaErrorState(
        error: .offline,
        onRetry: noop,
        onCancel: noop
    )
    .background(LuminaColors.parchment)
}
