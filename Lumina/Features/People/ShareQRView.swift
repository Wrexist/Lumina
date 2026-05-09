import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

/// "Share my chart" QR code. Encodes the user's saved `BirthData` as a
/// `lumina://share/<base64-json>` URL — the same scheme `LuminaDeepLink`
/// already parses. The other person scans with any camera app or the
/// Lumina QR scanner (Phase 10 follow-up) to add the user as a friend.
///
/// We never put auth tokens or user IDs in the QR — only the birth-data
/// payload. See `docs/NAVIGATION.md` §10 / Phase 10 of the roadmap.
struct ShareQRView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var qrImage: UIImage?
    @State private var error: LuminaError?

    var body: some View {
        NavigationStack {
            VStack(spacing: LuminaSpacing.lg) {
                explainer
                Spacer()
                qrSurface
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
        Text("Have a friend scan this QR with the Lumina app to add you. Only your birth data travels — no account info.")
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
        } else if let error {
            LuminaErrorState(error: error, onRetry: handleRetry, onCancel: handleCancel)
        } else {
            LuminaSkeleton(shape: .block(height: 280))
                .frame(maxWidth: 320)
        }
    }

    private var footer: some View {
        Text("This QR works with any camera app — they don't need Lumina installed.")
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

    private func handleCancel() {
        dismiss()
    }

    private func generate() {
        guard let birthData = UserBirthDataStore.userDefaults.load() else {
            error = .missingConfiguration(key: "BirthData")
            return
        }
        do {
            let json = try JSONEncoder.shareEncoder.encode(birthData)
            let payload = json.base64EncodedString()
            let url = "lumina://share/\(payload)"
            qrImage = Self.makeQR(for: url)
            if qrImage == nil {
                error = .unknown(underlyingMessage: "Couldn't render the QR code.")
            }
        } catch {
            self.error = LuminaError.from(error)
        }
    }
}

private extension JSONEncoder {
    static let shareEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
