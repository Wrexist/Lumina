import SwiftUI
import UIKit

/// Prominent "share this match" affordance — renders `CompatibilityShareCard`
/// to a PNG on a temp URL and hands it to a `ShareLink`. A file URL is the most
/// robust thing to share. Self-contained so `FriendDetailView` stays lean.
///
/// The temp file is named per friend and the render task is keyed to the
/// friend's identity — a single fixed filename let friend A's pending share
/// sheet pick up friend B's freshly rendered card.
struct CompatibilityShareButton: View {
    let friendName: String
    let score: Int
    let headline: String
    @State private var shareURL: URL?
    @State private var previewImage: Image?

    var body: some View {
        Group {
            if let shareURL, let previewImage {
                ShareLink(
                    item: shareURL,
                    preview: SharePreview("You + \(friendName)", image: previewImage)
                ) {
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
        .task(id: renderIdentity) { renderShareFile() }
    }

    /// Re-renders whenever the friend (or their score copy) changes, even if
    /// SwiftUI reuses this view's identity across friends.
    private var renderIdentity: String {
        "\(friendName)|\(score)|\(headline)"
    }

    /// Deterministic per-friend filename: a readable slug of the name plus a
    /// stable hash of the exact name, so "Anna B" and "Anna-B" (or two
    /// friends whose slugs collide) never overwrite each other's card.
    static func shareFileName(for friendName: String) -> String {
        var hash: UInt64 = 5381
        for byte in friendName.utf8 {
            hash = (hash &* 33) &+ UInt64(byte)
        }
        let slugCharacters = friendName.lowercased().map { char -> Character in
            char.isLetter || char.isNumber ? char : "-"
        }
        let slug = String(slugCharacters.prefix(24))
        return "lumina-compatibility-\(slug)-\(String(hash, radix: 16)).png"
    }

    private func renderShareFile() {
        let card = CompatibilityShareCard(friendName: friendName, score: score, headline: headline)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 2
        guard let uiImage = renderer.uiImage, let data = uiImage.pngData() else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(Self.shareFileName(for: friendName))
        do {
            try data.write(to: url)
            shareURL = url
            previewImage = Image(uiImage: uiImage)
        } catch {
            shareURL = nil
            previewImage = nil
        }
    }
}
