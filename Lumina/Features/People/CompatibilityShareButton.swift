import SwiftUI
import UIKit

/// Prominent "share this match" affordance — renders `CompatibilityShareCard`
/// to a PNG on a temp URL and hands it to a `ShareLink`. A file URL is the most
/// robust thing to share. Self-contained so `FriendDetailView` stays lean.
struct CompatibilityShareButton: View {
    let friendName: String
    let score: Int
    let headline: String
    @State private var shareURL: URL?

    var body: some View {
        Group {
            if let shareURL {
                ShareLink(item: shareURL) {
                    Label("Share this match", systemImage: "square.and.arrow.up")
                        .font(LuminaTypography.body)
                        .foregroundStyle(LuminaColors.celestialBlue)
                        .frame(maxWidth: .infinity)
                        .padding(LuminaSpacing.md)
                        .background(LuminaColors.celestialBlue.opacity(0.1))
                        .luminaCornerRadius(LuminaRadii.md)
                }
                .accessibilityLabel("Share your compatibility")
            }
        }
        .task { renderShareFile() }
    }

    private func renderShareFile() {
        let card = CompatibilityShareCard(friendName: friendName, score: score, headline: headline)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 2
        guard let uiImage = renderer.uiImage, let data = uiImage.pngData() else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("lumina-compatibility.png")
        do {
            try data.write(to: url)
            shareURL = url
        } catch {
            shareURL = nil
        }
    }
}
