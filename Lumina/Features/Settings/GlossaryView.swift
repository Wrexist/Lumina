import SwiftUI

/// A browsable reference of every term in the app, grouped by category, in
/// plain language. Surfaces the glossary content — previously reachable only
/// via inline `GlossaryLink` (used nowhere, since a `Button` can't sit inside
/// a flowing `Text`) — so a newcomer can look anything up. Linked from Help.
struct GlossaryView: View {
    @Environment(GlossaryStore.self) private var glossary
    @State private var selected: GlossaryEntry?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                Text("Plain-language definitions for every astrology, palmistry, and Human Design term in Lumina. Tap any one to read more.")
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                ForEach(GlossaryEntry.Category.allCases, id: \.self) { category in
                    section(for: category)
                }
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle("Glossary")
        .navigationBarTitleDisplayMode(.inline)
        .task { glossary.loadIfNeeded() }
        .sheet(item: $selected) { entry in
            GlossarySheet(term: entry.displayName, entry: entry)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func section(for category: GlossaryEntry.Category) -> some View {
        let items = entries(in: category)
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text(categoryTitle(category).uppercased())
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                ForEach(items) { entry in
                    termRow(entry)
                }
            }
        }
    }

    private func termRow(_ entry: GlossaryEntry) -> some View {
        Button { selected = entry } label: {
            LuminaCard(padding: LuminaSpacing.md) {
                VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                    Text(entry.displayName)
                        .font(LuminaTypography.body)
                    Text(entry.summary)
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(entry.displayName)
        .accessibilityHint("Read the full definition")
    }

    private func entries(in category: GlossaryEntry.Category) -> [GlossaryEntry] {
        glossary.entries.values
            .filter { $0.category == category }
            .sorted { $0.displayName < $1.displayName }
    }

    private func categoryTitle(_ category: GlossaryEntry.Category) -> String {
        switch category {
        case .astrology: "Astrology"
        case .humanDesign: "Human Design"
        case .palmistry: "Palmistry"
        case .general: "General"
        }
    }
}
