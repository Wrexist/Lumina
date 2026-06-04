import SwiftUI

/// Phase-12 / Phase-13 starter Help & FAQ. Twelve hand-written articles
/// grouped by topic, fully on-device. The pull-down search on Today
/// (Phase 13) will index this content alongside the glossary.
struct HelpView: View {
    fileprivate struct Article: Identifiable, Hashable {
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
              body: "Lumina is a premium astrology and palm-reading app. We use real Swiss-Ephemeris chart math, "
                  + "on-device palm analysis, and interpretations grounded in your actual chart — "
                  + "never generic horoscope copy."),
        .init(id: "what-time-do-i-need", topic: .gettingStarted, title: "Why do you need my birth time?",
              body: "The exact time decides your rising sign and which house each planet falls into. Without time "
                  + "we still calculate your sign and planets — only houses are hidden. You can always update it "
                  + "later in Settings → Your info."),
        .init(id: "wrong-time", topic: .gettingStarted, title: "I think I entered the wrong time",
              body: "Open Settings → Your info, change the time, and save. The Chart tab re-computes the next time you open it."),
        .init(id: "asc-hidden", topic: .chart, title: "My Ascendant says \"hidden\"",
              body: "The Ascendant requires your birth time to compute. Open Settings → Your info to add it; otherwise the chart still ships your real sign and planets."),
        .init(id: "house-systems", topic: .chart, title: "Placidus vs Whole-sign vs Sidereal",
              body: "Placidus is the modern Western default. Whole-sign is older and matches the sign-aligned "
                  + "approach. Sidereal aligns with the actual constellations (Vedic). Pick the one your tradition "
                  + "uses — your planets stay the same, only the houses shift."),
        .init(id: "retrograde-marker", topic: .chart, title: "What's the ℞ marker?",
              body: "It's the traditional retrograde marker — the planet appears to move backwards from Earth's "
                  + "vantage point. Astrologers read it as an invitation to revisit, review, or revise rather "
                  + "than initiate."),
        .init(id: "palm-when", topic: .palm, title: "When does palm scanning arrive?",
              body: "It's coming soon. We're making sure the on-device line tracing works fairly across every "
                  + "skin tone before we ship it — that's the part we won't rush. The walkthrough in the Palm "
                  + "tab shows exactly how it will run on your phone."),
        .init(id: "palm-photo", topic: .palm, title: "Does my palm photo leave my phone?",
              body: "No. Your phone finds your hand and traces the lines on-device, then turns them into about "
                  + "50 numbers (line lengths, curvature). Only those numbers go to our server — never the "
                  + "photo. See the full walkthrough in Palm → How this works."),
        .init(id: "add-friend", topic: .people, title: "How do I add someone?",
              body: "Open the People tab and tap the + menu. \"Add someone\" opens a manual form; \"Share my chart\" generates a QR a friend can scan with any camera app."),
        .init(id: "compatibility-score", topic: .people, title: "How is compatibility calculated?",
              body: "The headline score is a quick read from your Sun signs' element and modality. Open any "
                  + "friend to see the real chart-to-chart aspects between you — \"your Venus conjunct their "
                  + "Mars\" — and a fuller weighted score is coming soon."),
        .init(id: "data-storage", topic: .privacy, title: "Where does my data live?",
              body: "Your chart, friends, and Reflect entries live on this device only. Open Settings → Privacy → Privacy dashboard to see exactly what's where."),
        .init(id: "subscription", topic: .billing, title: "How do I cancel my subscription?",
              body: "Settings → Account → Manage subscription opens Apple's native subscription management screen. We never bury cancel — that's a brand pillar."),
    ]

    @State private var query = ""

    // No own NavigationStack: HelpView is either pushed inside the Settings
    // stack or wrapped in a NavigationStack when presented as a sheet — a
    // nested stack here produced a double nav bar and a "Done" that popped one
    // level instead of closing the sheet.
    var body: some View {
        List {
            if !query.isEmpty {
                searchResults
            } else {
                Section {
                    NavigationLink {
                        GlossaryView()
                    } label: {
                        HStack {
                            Image(systemName: "character.book.closed")
                            Text("Glossary — every term, explained")
                        }
                    }
                }
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
    @State private var message = ""

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
                    TextEditor(text: $message)
                        .font(LuminaTypography.body)
                        .scrollContentBackground(.hidden)
                        .background(LuminaColors.parchment)
                        .frame(minHeight: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: LuminaRadii.sm, style: .continuous)
                                .stroke(LuminaColors.inkBlack.opacity(0.2), lineWidth: 1)
                        )
                }
                LuminaButton(title: "Send", variant: .primary, isEnabled: !message.trimmingCharacters(in: .whitespaces).isEmpty) {
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
    NavigationStack { HelpView() }
}
