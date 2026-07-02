import CoreTransferable
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Compact share icon for the daily-reading card. The share PNG renders
/// lazily — only when the user actually commits to sharing — via a
/// `Transferable` file representation, so Today never pays the render cost
/// up front. Self-contained so `TodayHubView` stays lean.
struct DailyReadingShareButton: View {
    let reading: String
    let date: Date

    var body: some View {
        ShareLink(
            item: ShareableDailyReading(reading: reading, date: date),
            preview: SharePreview("Today's reading")
        ) {
            Image(systemName: "square.and.arrow.up")
                .foregroundStyle(LuminaColors.celestialBlue)
        }
        .accessibilityLabel("Share today's reading")
    }
}

/// Renders `DailyReadingShareCard` to a date-stamped temp PNG on demand.
private struct ShareableDailyReading: Transferable {
    let reading: String
    let date: Date

    enum RenderError: Error {
        case renderingFailed
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .png) { shareable in
            SentTransferredFile(try await shareable.renderFile())
        }
    }

    /// `ImageRenderer` is main-actor-bound; this hop is the one place we pay
    /// the render, right as the share sheet needs the file.
    @MainActor
    private func renderFile() throws -> URL {
        let card = DailyReadingShareCard(reading: reading, date: date)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 2
        guard let uiImage = renderer.uiImage, let data = uiImage.pngData() else {
            throw RenderError.renderingFailed
        }
        // Date-stamped so yesterday's shared file never masquerades as today's.
        let stamp = date.formatted(.iso8601.year().month().day())
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("lumina-reading-\(stamp).png")
        try data.write(to: url)
        return url
    }
}
