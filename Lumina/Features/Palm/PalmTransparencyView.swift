import SwiftUI

/// "How this works" transparency sheet for the Palm tab. Per
/// `ROADMAP.md` Phase 6 and brand pillar #1 — the Lumina differentiator
/// is REAL palm CV that runs on-device. The sheet exists so users can
/// see the privacy promise before consenting to camera access.
struct PalmTransparencyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                    hero
                    LuminaCard {
                        VStack(alignment: .leading, spacing: LuminaSpacing.md) {
                            row("01", title: "Camera frame", body: "AVFoundation gives us a live preview. Your phone never starts recording — we look at frames in memory only.")
                            row("02", title: "Hand pose", body: "Apple's Vision framework finds the 21 "
                                + "hand-pose landmarks (wrist, finger joints) in each frame. Used only to "
                                + "know when your hand is positioned right.")
                            row("03", title: "Line segmentation", body: "A small Core ML model — bundled "
                                + "with the app — traces the four major lines on a 256×256 grayscale crop. "
                                + "Inference runs entirely on the Neural Engine.")
                            row("04", title: "Feature extraction", body: "We turn the trace into about 50 numbers (line lengths, curvature, branch counts). The image is dropped from memory.")
                            row("05", title: "Reading", body: "Only those numbers + your chart go to the server for the narrated reading. The photo never leaves your phone.")
                        }
                    }
                    promiseCard
                }
                .padding(LuminaSpacing.lg)
            }
            .background(LuminaColors.parchment)
            .navigationTitle("How this works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - View building blocks

    private var hero: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
            Text("Real palm CV")
                .font(LuminaTypography.heading)
            Text("Most apps in this category fake the analysis with a generic illustration. Lumina actually traces your hand on-device.")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.8))
        }
    }

    private var promiseCard: some View {
        LuminaCard(surface: .glass) {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                HStack(spacing: LuminaSpacing.sm) {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(LuminaColors.celestialBlue)
                    Text("Our privacy promise")
                        .font(LuminaTypography.heading)
                }
                Text("No palm photo bytes ever leave your device. We invite anyone to verify with "
                    + "Charles or Proxyman — see the network log entry in Settings → Privacy dashboard "
                    + "once it ships (Phase 12).")
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
            }
        }
    }

    private func row(_ number: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: LuminaSpacing.md) {
            Text(number)
                .font(LuminaTypography.mono)
                .foregroundStyle(LuminaColors.mutedGold)
                .frame(width: 32, alignment: .leading)
            VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                Text(title)
                    .font(LuminaTypography.body)
                    .bold()
                Text(body)
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.75))
            }
        }
    }
}

#Preview {
    PalmTransparencyView()
}
