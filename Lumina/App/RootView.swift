import SwiftUI

struct RootView: View {
    var body: some View {
        ZStack {
            LuminaColors.parchment
                .ignoresSafeArea()

            VStack(spacing: LuminaSpacing.md) {
                Text("Lumina")
                    .font(LuminaTypography.display)
                    .foregroundStyle(LuminaColors.inkBlack)

                Text("Finally, a real one.")
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.celestialBlue)
            }
            .padding(LuminaSpacing.lg)
        }
    }
}

#Preview {
    RootView()
}
