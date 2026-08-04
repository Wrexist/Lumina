import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

/// "Share my chart" QR code. Encodes a deliberately-reduced `SharedBirthData`
/// (birth date + city + coarse coordinates, never the exact time or precise
/// location) as a `https://lumina.app/share/<base64url-json>` universal link
/// — the same shape `LuminaDeepLink` parses. The other person opens it in
/// Lumina to add the user as a friend; if they don't have Lumina installed,
/// the link falls back to a normal web page instead of doing nothing (the
/// reason this uses a universal link rather than the `lumina://` scheme —
/// see `docs/CAPABILITIES-PLAN.md` §4).
///
/// We never put auth tokens, user IDs, exact birth time, or precise
/// coordinates in the QR. See docs/AUDIT-2026-06-03.md R2 / `SharedBirthData`.
struct ShareQRView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @State private var qrImage: UIImage?
    @State private var shareURL: URL?
    @State private var error: LuminaError?
    /// Distinct from `error`: there is nothing wrong, the user simply hasn't
    /// entered their birth info yet. Rendering that as a failure told them
    /// "App is mid-setup", which blames the app for the user's next step.
    @State private var needsBirthInfo = false

    var body: some View {
        NavigationStack {
            VStack(spacing: LuminaSpacing.lg) {
                explainer
                Spacer()
                qrSurface
                sendLinkButton
                Spacer()
                footer
            }
            .padding(LuminaSpacing.lg)
            .background(LuminaColors.parchment)
            .navigationTitle("Share my chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task { generate() }
        }
    }

    // MARK: - View building blocks

    private var explainer: some View {
        Text("Have a friend scan this with the Lumina app to add you. Only your birth date and city are shared — never your exact birth time or precise location.")
            .font(LuminaTypography.bodyLight)
            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var qrSurface: some View {
        if let qrImage {
            Image(uiImage: qrImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .padding(LuminaSpacing.lg)
                .background(LuminaColors.parchment)
                .luminaCornerRadius(LuminaRadii.md)
                .overlay(
                    RoundedRectangle(cornerRadius: LuminaRadii.md, style: .continuous)
                        .stroke(LuminaColors.inkBlack.opacity(0.12), lineWidth: 1)
                )
                .frame(maxWidth: 320)
                .accessibilityLabel("Lumina share QR code")
        } else if needsBirthInfo {
            LuminaEmptyState(
                systemImage: "person.crop.circle.badge.plus",
                title: "Add your birth info first",
                body: "Your share code is built from your birth date and city, so we need those before there's anything to share.",
                primaryCTA: LuminaEmptyState.CTA(title: "Add birth info", action: openBirthInfo)
            )
        } else if let error {
            LuminaErrorState(error: error, onRetry: handleRetry, onCancel: handleCancel)
        } else {
            LuminaSkeleton(shape: .block(height: 280))
                .frame(maxWidth: 320)
        }
    }

    /// Not everyone is in the same room — the same universal link the QR
    /// encodes can be sent over Messages/WhatsApp instead.
    @ViewBuilder
    private var sendLinkButton: some View {
        if let shareURL {
            ShareLink(
                item: shareURL,
                preview: SharePreview("Add me on Lumina")
            ) {
                Label("Send the link", systemImage: "paperplane")
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.celestialBlue)
                    .frame(maxWidth: .infinity)
                    .padding(LuminaSpacing.md)
                    .background(LuminaColors.celestialBlue.opacity(0.1))
                    .luminaCornerRadius(LuminaRadii.md)
            }
            .accessibilityLabel("Send your share link")
        }
    }

    private var footer: some View {
        Text("Open it in the Lumina app to connect. Your journal, friends, and account stay private.")
            .font(LuminaTypography.caption)
            .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            .multilineTextAlignment(.center)
    }

    // MARK: - Methods

    private static func makeQR(for string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scale = CGAffineTransform(scaleX: 8, y: 8)
        let scaled = output.transformed(by: scale)
        let context = CIContext()
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }

    private func handleRetry() {
        error = nil
        generate()
    }

    private func openBirthInfo() {
        dismiss()
        router.openSettings(.birthInfo)
    }

    private func handleCancel() {
        dismiss()
    }

    private func generate() {
        needsBirthInfo = false
        guard let birthData = UserBirthDataStore.userDefaults.load() else {
            needsBirthInfo = true
            return
        }
        do {
            let shared = SharedBirthData(from: birthData)
            let json = try JSONEncoder.luminaShare.encode(shared)
            let payload = json.base64URLEncodedString()
            let urlString = "https://\(LuminaDeepLink.universalLinkHost)/share/\(payload)"
            qrImage = Self.makeQR(for: urlString)
            if qrImage == nil {
                error = .unknown(underlyingMessage: "Couldn't render the QR code.")
            } else {
                shareURL = URL(string: urlString)
            }
        } catch {
            self.error = LuminaError.from(error)
        }
    }
}
