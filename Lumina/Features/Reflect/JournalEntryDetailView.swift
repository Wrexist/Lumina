import SwiftData
import SwiftUI

/// Read-only detail view for a previously written journal entry. The
/// "Edit" button hands off to `JournalEntryView` for changes.
struct JournalEntryDetailView: View {
    let entry: JournalEntry

    @Environment(\.modelContext) private var modelContext
    @State private var editing = false
    @State private var confirmingDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                header
                promptCard
                bodyCard
                metaRow
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle(formattedDate)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { trailingToolbar }
        .navigationDestination(isPresented: $editing) {
            JournalEntryView(entry: entry)
        }
        .luminaConfirmation(
            "Delete this entry?",
            message: "This can't be undone.",
            confirmTitle: "Delete",
            isPresented: $confirmingDelete,
            onConfirm: handleDelete
        )
    }

    // MARK: - Sub-views

    private var header: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
            Text("REFLECTION")
                .font(LuminaTypography.mono)
                .tracking(1.4)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
        }
    }

    private var promptCard: some View {
        LuminaCard(surface: .glass) {
            Text(entry.prompt)
                .font(LuminaTypography.heading)
        }
    }

    @ViewBuilder
    private var bodyCard: some View {
        if entry.body.isEmpty {
            Text("You didn't write anything that day.")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.5))
        } else {
            Text(entry.body)
                .font(LuminaTypography.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
        }
    }

    private var metaRow: some View {
        HStack {
            Text("\(entry.wordCount) words")
                .font(LuminaTypography.mono)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.5))
            Spacer()
            Text("Edited \(relativeUpdatedAt)")
                .font(LuminaTypography.caption)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.5))
        }
    }

    @ToolbarContentBuilder
    private var trailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Edit", systemImage: "pencil") { editing = true }
                Button("Delete", systemImage: "trash", role: .destructive) {
                    confirmingDelete = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("Entry options")
        }
    }

    // MARK: - Logic

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE · MMM d"
        return formatter.string(from: entry.date)
    }

    private var relativeUpdatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: entry.updatedAt, relativeTo: .now)
    }

    private func handleDelete() {
        modelContext.delete(entry)
        modelContext.saveOrLog(category: "Reflect")
    }
}
