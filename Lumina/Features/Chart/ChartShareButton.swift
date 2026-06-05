import SwiftUI
import UIKit

/// Toolbar share affordance for the Chart tab. Renders `ChartShareCard` to a
/// PNG on a temp URL and hands it to a `ShareLink` (a file URL is the most
/// robust thing to share). Self-contained so `ChartHubView` stays lean.
struct ChartShareButton: View {
    let chart: NatalChart
    @State private var shareURL: URL?

    var body: some View {
        Group {
            if let shareURL {
                ShareLink(item: shareURL) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share your chart")
            }
        }
        .task { renderShareFile() }
    }

    private func renderShareFile() {
        let renderer = ImageRenderer(content: ChartShareCard(chart: chart))
        renderer.scale = 2
        guard let uiImage = renderer.uiImage, let data = uiImage.pngData() else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("lumina-chart.png")
        do {
            try data.write(to: url)
            shareURL = url
        } catch {
            shareURL = nil
        }
    }
}
