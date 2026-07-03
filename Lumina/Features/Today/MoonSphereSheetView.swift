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

    /// Spoken description of the sphere for VoiceOver — the phase name plus
    /// how much of the disc is lit, so the info conveyed visually by the 3D
    /// terminator is also available non-visually.
    private var sphereAccessibilityLabel: String {
        let percent = Int((phase.illumination * 100).rounded())
        return "The Moon tonight — \(phase.phase), \(percent)% lit"
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Stars sit between the midnight background and the (clear-
                // backed) SceneKit view, so the moon floats in a starfield.
                LuminaStarfield(tint: LuminaColors.mutedGold.opacity(0.85))
                    .ignoresSafeArea()
                MoonSphere3DView(phase: phase, reduceMotion: reduceMotion)
                    .ignoresSafeArea()
                    // The raw SceneKit `SCNView` exposes an unlabeled
                    // interactive element; collapse it into one described
                    // element so VoiceOver announces the actual phase.
                    .accessibilityElement()
                    .accessibilityLabel(sphereAccessibilityLabel)
                    .accessibilityHint("Drag to explore the Moon's surface.")
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
