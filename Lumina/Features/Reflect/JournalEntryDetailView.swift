import SwiftData
import SwiftUI

/// Read-only detail view for a previously written journal entry. The
/// "Edit" button hands off to `JournalEntryView` for changes.
struct JournalEntryDetailView: View {
    let entry: JournalEntry

    @Environment(\.dismiss) private var dismiss
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
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
        } else {
            Text(entry.body)
                .font(LuminaTypography.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
        }
    }

    private var metaRow: some View {
        HStack {
            Text("^[\(entry.wordCount) word](inflect: true)")
                .font(LuminaTypography.mono)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            Spacer()
            Text("Edited \(relativeUpdatedAt)")
                .font(LuminaTypography.caption)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
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
        let weekday = entry.date.formatted(.dateTime.weekday(.wide))
        let monthDay = entry.date.formatted(.dateTime.month(.abbreviated).day())
        return "\(weekday) · \(monthDay)"
    }

    private var relativeUpdatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: entry.updatedAt, relativeTo: .now)
    }

    private func handleDelete() {
        // Order matters. `dismiss()` is asynchronous — the pop animation runs
        // for ~350ms with this view still mounted — while `delete` + `save`
        // invalidates the model and fires observation, which re-evaluates
        // `body`. `body` reads `entry.prompt`, `entry.body`, `entry.wordCount`,
        // `entry.updatedAt` and `entry.date`, and reading a persistent
        // property off an invalidated `PersistentModel` is a hard crash.
        //
        // So: start the dismissal, let this view unmount, and delete on the
        // next runloop turn. Capture the model first — `entry` is a `let` on
        // the view, which is gone by the time the closure runs.
        let doomed = entry
        let context = modelContext
        dismiss()
        Task { @MainActor in
            context.delete(doomed)
            context.saveOrLog(category: "Reflect")
        }
    }
}
