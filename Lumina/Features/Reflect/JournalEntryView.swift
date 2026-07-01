import SwiftData
import SwiftUI

/// Full-screen reflection editor. Auto-saves with 1s debounce so a force
/// quit during typing doesn't lose anything. No streaks, no celebratory
/// animation — see the brand pillar "anti-Duolingo" in
/// `docs/NAVIGATION.md` §15.
struct JournalEntryView: View {
    let entry: JournalEntry

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var draft = ""
    @State private var hydrated = false
    @State private var saveTask: Task<Void, Never>?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
            promptCard
            editor
            footer
        }
        .padding(LuminaSpacing.lg)
        .background(LuminaColors.parchment)
        .navigationTitle(formattedDate)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { trailingToolbar }
        .onChange(of: draft) { _, newValue in
            guard hydrated else { return }
            scheduleSave(newValue)
        }
        .onChange(of: scenePhase) { _, phase in
            // Flush the debounce window if the app is backgrounded mid-edit.
            if phase != .active { saveImmediately() }
        }
        .onDisappear { saveImmediately() }
        .task(id: entry.id) {
            draft = entry.body
            hydrated = true
            focused = draft.isEmpty
        }
    }

    // MARK: - Sub-views

    private var promptCard: some View {
        LuminaCard(surface: .glass) {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("TODAY'S PROMPT")
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                Text(entry.prompt)
                    .font(LuminaTypography.heading)
            }
        }
    }

    private var editor: some View {
        TextEditor(text: $draft)
            .font(LuminaTypography.body)
            .scrollContentBackground(.hidden)
            .background(LuminaColors.parchment)
            .focused($focused)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel("Reflection editor")
    }

    private var footer: some View {
        HStack {
            Text("\(JournalEntry.countWords(in: draft)) words")
                .font(LuminaTypography.mono)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.5))
            Spacer()
            Text(saveLabel)
                .font(LuminaTypography.caption)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.5))
        }
    }

    @ToolbarContentBuilder
    private var trailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Done") {
                saveImmediately()
                dismiss()
            }
            .accessibilityLabel("Save and close")
        }
    }

    // MARK: - Logic

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE · MMM d"
        return formatter.string(from: entry.date)
    }

    private var saveLabel: String {
        if saveTask != nil { return "Saving…" }
        if draft == entry.body { return "Saved" }
        return "Editing"
    }

    private func scheduleSave(_ newValue: String) {
        saveTask?.cancel()
        saveTask = Task { [newValue] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            commit(newValue)
            saveTask = nil
        }
    }

    private func saveImmediately() {
        saveTask?.cancel()
        saveTask = nil
        commit(draft)
    }

    private func commit(_ text: String) {
        guard text != entry.body else { return }
        entry.apply(body: text)
        modelContext.saveOrLog(category: "Reflect")
    }
}
