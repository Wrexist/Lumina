import SwiftUI

/// Phase-12 / Phase-13 starter Help & FAQ. Twelve hand-written articles
/// grouped by topic, fully on-device. The pull-down search on Today
/// (Phase 13) will index this content alongside the glossary.
struct HelpView: View {
    private struct Article: Identifiable, Hashable {
        let id: String
        let topic: Topic
        let title: String
        let body: String
    }

    enum Topic: String, CaseIterable, Hashable, Identifiable, Sendable {
        case gettingStarted
        case chart
        case palm
        case people
        case privacy
        case billing

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .gettingStarted: "Getting started"
            case .chart: "Your chart"
            case .palm: "Palm reading"
            case .people: "People"
            case .privacy: "Privacy"
            case .billing: "Billing & subscription"
            }
        }
    }

    private static let allArticles: [Article] = [
        .init(id: "what-is-lumina", topic: .gettingStarted, title: "What is Lumina?",
              body: "Lumina is a premium astrology and palm-reading app. We use real Swiss-Ephemeris chart math, on-device computer-vision palm analysis, and RAG-grounded language-model interpretations — never generic horoscope copy."),
        .init(id: "what-time-do-i-need", topic: .gettingStarted, title: "Why do you need my birth time?",
              body: "The exact time decides your rising sign and which house each planet falls into. Without time we still calculate your sign and planets — only houses are hidden. You can always update it later in Settings → Your info."),
        .init(id: "wrong-time", topic: .gettingStarted, title: "I think I entered the wrong time",
              body: "Open Settings → Your info, change the time, and save. The Chart tab re-computes the next time you open it."),
        .init(id: "asc-hidden", topic: .chart, title: "My Ascendant says \"hidden\"",
              body: "The Ascendant requires your birth time to compute. Open Settings → Your info to add it; otherwise the chart still ships your real sign and planets."),
        .init(id: "house-systems", topic: .chart, title: "Placidus vs Whole-sign vs Sidereal",
              body: "Placidus is the modern Western default. Whole-sign is older and matches the sign-aligned approach. Sidereal aligns with the actual constellations (Vedic). Pick the one your tradition uses — your planets stay the same, only the houses shift."),
        .init(id: "retrograde-marker", topic: .chart, title: "What's the ℞ marker?",
              body: "It's the traditional retrograde marker — the planet appears to move backwards from Earth's vantage point. Astrologers read it as an invitation to revisit, review, or revise rather than initiate."),
        .init(id: "palm-when", topic: .palm, title: "When does palm scanning ship?",
              body: "Palm scanning ships in Phase 6 of the roadmap once the on-device Core ML model is balanced across skin tones. The transparency walkthrough in the Palm tab shows exactly how the pipeline runs locally."),
        .init(id: "palm-photo", topic: .palm, title: "Does my palm photo leave my phone?",
              body: "No. Vision detects your hand; a Core ML model traces the lines; we extract about 50 numbers (line lengths, curvature). Only those numbers go to our server — never the photo. Read the full pipeline in Palm → How this works."),
        .init(id: "add-friend", topic: .people, title: "How do I add someone?",
              body: "Open the People tab and tap the + menu. \"Add someone\" opens a manual form; \"Share my chart\" generates a QR a friend can scan with any camera app."),
        .init(id: "compatibility-score", topic: .people, title: "How is the compatibility score calculated?",
              body: "Today's score uses a deterministic algorithm based on Sun-sign element + modality. The full synastry score (with cross-chart aspects, weighted by orb) ships in Phase 7 once the backend `/synastry` endpoint is live."),
        .init(id: "data-storage", topic: .privacy, title: "Where does my data live?",
              body: "Your chart, friends, and Reflect entries live on this device only. Open Settings → Privacy → Privacy dashboard to see exactly what's where."),
        .init(id: "subscription", topic: .billing, title: "How do I cancel my subscription?",
              body: "Settings → Account → Manage subscription opens Apple's native subscription management screen. We never bury cancel — that's a brand pillar."),
    ]

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                if !query.isEmpty {
                    searchResults
                } else {
                    ForEach(Topic.allCases) { topic in
                        Section(topic.displayName) {
                            ForEach(articles(for: topic)) { article in
                                NavigationLink {
                                    ArticleView(article: article)
                                } label: {
                                    Text(article.title).font(LuminaTypography.body)
                                }
                            }
                        }
                    }
                    Section {
                        NavigationLink {
                            FeedbackView()
                        } label: {
                            HStack {
                                Image(systemName: "envelope")
                                Text("Send feedback")
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(LuminaColors.parchment)
            .searchable(text: $query, prompt: "Search help")
            .navigationTitle("Help & FAQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        let matches = Self.allArticles.filter { article in
            article.title.localizedCaseInsensitiveContains(query)
                || article.body.localizedCaseInsensitiveContains(query)
        }
        if matches.isEmpty {
            Section {
                Text("No matches. Try a different word.")
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            }
        } else {
            Section("Results") {
                ForEach(matches) { article in
                    NavigationLink {
                        ArticleView(article: article)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(article.title).font(LuminaTypography.body)
                            Text(article.topic.displayName)
                                .font(LuminaTypography.caption)
                                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                        }
                    }
                }
            }
        }
    }

    private func articles(for topic: Topic) -> [Article] {
        Self.allArticles.filter { $0.topic == topic }
    }
}

private struct ArticleView: View {
    let article: HelpView.Article

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.md) {
                Text(article.topic.displayName.uppercased())
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                Text(article.title)
                    .font(LuminaTypography.heading)
                Text(article.body)
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle(article.topic.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FeedbackView: View {
    @State private var subject = ""
    @State private var body = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                Text("Tell us what's working, what isn't, what you wish was here. We read every note.")
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                LuminaTextField(title: "Subject", text: $subject, placeholder: "Optional")
                VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                    Text("MESSAGE")
                        .font(LuminaTypography.caption)
                        .tracking(1.2)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                    TextEditor(text: $body)
                        .font(LuminaTypography.body)
                        .scrollContentBackground(.hidden)
                        .background(LuminaColors.parchment)
                        .frame(minHeight: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: LuminaRadii.sm, style: .continuous)
                                .stroke(LuminaColors.inkBlack.opacity(0.2), lineWidth: 1)
                        )
                }
                LuminaButton(title: "Send", variant: .primary, isEnabled: !body.trimmingCharacters(in: .whitespaces).isEmpty) {
                    // TODO(lumina): wire MFMailComposeViewController + diagnostic dump (Phase 12)
                    Haptics.success.play()
                }
                Text("In the next phase this opens Mail with a diagnostic-dump attachment (device, build, anonymised state).")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.5))
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle("Send feedback")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HelpView()
}
