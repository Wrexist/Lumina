import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// The Privacy section of Settings: the dashboard, and the data export.
///
/// Its own view rather than a `private var` on `SettingsView` because the
/// export needs four pieces of state and two `@Query`s of its own, and
/// `SettingsView` is already at SwiftLint's type-body ceiling. Keeping the
/// section self-contained also means the export's failure states live next to
/// the button that can produce them.
struct SettingsPrivacySection: View {
    @Query private var journalEntries: [JournalEntry]
    @Query private var friends: [Friend]

    @State private var exportDocument: LuminaExportDocument?
    @State private var exportPresented = false
    @State private var exportMessage: String?

    var body: some View {
        Section {
            NavigationLink {
                PrivacyDashboardView()
            } label: {
                SettingsRow(title: "Privacy dashboard", trailing: nil)
            }
            Button(action: prepareExport) {
                SettingsRow(title: "Export my data", trailing: nil)
            }
            .buttonStyle(.plain)
            if let exportMessage {
                Text(exportMessage)
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.error)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } header: {
            Text("Privacy")
        } footer: {
            Text("Delete your account any time from the Account section above. "
                + "Export writes everything on this device to a JSON file you choose where "
                + "to save — nothing is uploaded.")
                .font(LuminaTypography.caption)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
        }
        .fileExporter(
            isPresented: $exportPresented,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "lumina-data-export"
        ) { result in
            if case .failure = result {
                exportMessage = "The export wasn't saved. Please try again."
            }
        }
    }

    /// Builds the archive and hands it to the system save sheet. This screen
    /// used to promise export was "coming before public launch"; portability
    /// is also a GDPR Art. 20 / CCPA obligation, so it ships.
    private func prepareExport() {
        exportMessage = nil
        do {
            let export = LuminaDataExport.make(journalEntries: journalEntries, friends: friends)
            exportDocument = LuminaExportDocument(data: try export.encoded())
            exportPresented = true
        } catch {
            exportMessage = "We couldn't build your export. Please try again."
        }
    }
}
