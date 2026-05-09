import SwiftUI

/// Inline glossary trigger. Wrap any astrology / palmistry / Human-Design
/// term that appears in shipped UI body copy. Tapping presents the entry
/// as a sheet.
///
/// Two initialisers:
/// ```swift
/// GlossaryLink("Saturn return")                       // visible label = the term
/// GlossaryLink(term: "Saturn return") { Text("…") }   // custom label
/// ```
struct GlossaryLink<Label: View>: View {
    let term: String
    @ViewBuilder let label: () -> Label

    @State private var isPresented = false
    @Environment(GlossaryStore.self) private var glossary

    var body: some View {
        Button {
            isPresented = true
        } label: {
            label()
                .underline(true, color: LuminaColors.celestialBlue.opacity(0.5))
                .foregroundStyle(LuminaColors.celestialBlue)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Show definition of \(term)")
        .sheet(isPresented: $isPresented) {
            GlossarySheet(term: term, entry: glossary.entry(for: term))
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

extension GlossaryLink where Label == Text {
    /// Convenience initializer — uses the term itself as the visible label.
    init(_ term: String) {
        self.init(term: term) { Text(term) }
    }
}

/// The sheet that explains an entry. Falls back to a "no definition yet"
/// message if the term isn't in `Glossary.json`. We surface this as an
/// in-app feedback opportunity in v1.1.
struct GlossarySheet: View {
    let term: String
    let entry: GlossaryEntry?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.md) {
                if let entry {
                    LuminaBadge(title: entry.category.rawValue, tone: .neutral)
                    Text(entry.displayName)
                        .font(LuminaTypography.heading)
                    Text(entry.summary)
                        .font(LuminaTypography.body)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
                    Text(entry.body)
                        .font(LuminaTypography.body)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                } else {
                    Text(term)
                        .font(LuminaTypography.heading)
                    Text("We don't have a definition for this yet — we'll add it soon.")
                        .font(LuminaTypography.body)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                }
            }
            .padding(LuminaSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(LuminaColors.parchment)
    }
}
