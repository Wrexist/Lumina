import SwiftUI

/// The honest "nothing is retrograde" state for Today's sky-context strip.
///
/// It exists as its own view rather than inline in `TodayHubView` because that
/// file sits against SwiftLint's 400-line ceiling — a limit worth respecting
/// on the app's busiest screen.
struct NoRetrogradesCard: View {
    var body: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                Text("RETROGRADES")
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                Text("No retrogrades right now — all planets are direct.")
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
        }
    }
}

#Preview {
    NoRetrogradesCard().padding()
}
