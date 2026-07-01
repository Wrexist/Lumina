import SwiftUI

/// Full-bleed, interactive 3D Moon sheet — presented from `MoonPhaseCard`'s
/// "View in 3D" affordance. Mirrors `ShareQRView`'s sheet + `NavigationStack`
/// + top-trailing "Done" convention.
struct MoonSphereSheetView: View {
    let phase: MoonPhaseResult

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var preferences = AppPreferences.shared

    private var reduceMotion: Bool {
        LuminaMotion.isReduced(system: systemReduceMotion, appOverride: preferences.reduceMotionOverride)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                MoonSphere3DView(phase: phase, reduceMotion: reduceMotion)
                    .ignoresSafeArea()
                caption
            }
            .background(LuminaColors.midnight)
            .navigationTitle("Tonight's Moon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - View building blocks

    private var caption: some View {
        VStack(spacing: LuminaSpacing.xs) {
            Text(phase.phase)
                .font(LuminaTypography.heading)
                .foregroundStyle(LuminaColors.parchment)
            Text(MoonPhasePresentation.illuminationText(phase.illumination))
                .font(LuminaTypography.caption)
                .foregroundStyle(LuminaColors.parchment.opacity(0.7))
            Text("Drag to explore")
                .font(LuminaTypography.caption)
                .foregroundStyle(LuminaColors.parchment.opacity(0.5))
        }
        .padding(.bottom, LuminaSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [LuminaColors.midnight.opacity(0), LuminaColors.midnight.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview("Moon Sphere Sheet") {
    MoonSphereSheetView(
        phase: MoonPhaseResult(
            calculatedAt: .now,
            at: .now,
            angle: 180,
            phase: "Full Moon",
            illumination: 0.99,
            nextNewMoon: .now.addingTimeInterval(86_400 * 14),
            nextFullMoon: .now.addingTimeInterval(86_400 * 29)
        )
    )
}
