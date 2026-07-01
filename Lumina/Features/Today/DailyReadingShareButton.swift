import SwiftUI
import UIKit

/// Compact share icon for the daily-reading card — renders `DailyReadingShareCard`
/// to a temp PNG and shares the file URL via `ShareLink`. Self-contained so
/// `TodayHubView` stays lean.
struct DailyReadingShareButton: View {
    let reading: String
    let date: Date
    @State private var shareURL: URL?

    var body: some View {
        Group {
            if let shareURL {
                ShareLink(item: shareURL) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(LuminaColors.celestialBlue)
                }
                .accessibilityLabel("Share today's reading")
            }
        }
        .task(id: reading) { renderShareFile() }
    }

    private func renderShareFile() {
        let card = DailyReadingShareCard(reading: reading, date: date)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 2
        guard let uiImage = renderer.uiImage, let data = uiImage.pngData() else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("lumina-reading.png")
        do {
            try data.write(to: url)
            shareURL = url
        } catch {
            shareURL = nil
        }
    }
}
