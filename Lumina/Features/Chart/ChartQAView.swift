import SwiftUI

/// "Ask your chart". Two grounded modes: a free-text question answered by the
/// server-side LLM (when configured), and a curated set answered deterministically
/// straight from the chart via `ChartOracle`. The curated set always works — no
/// key required — so the screen is never empty. Pushed from the Chart tab.
struct ChartQAView: View {
    let chart: NatalChart
    @State private var selected: ChartQuestion = .bigThree
    @State private var viewModel = ChartQAViewModel()
    @State private var draft = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                intro
                if viewModel.offersConversation {
                    conversation
                }
                curated
                EntertainmentDisclaimer()
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle("Ask your chart")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension ChartQAView {
    var intro: some View {
        Text("Every answer is read straight from your real chart — never a generic horoscope.")
            .font(LuminaTypography.bodyLight)
            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Free-text (LLM) mode

    var conversation: some View {
        LuminaCard(surface: .glass) {
            VStack(alignment: .leading, spacing: LuminaSpacing.md) {
                Text("Ask anything")
                    .font(LuminaTypography.heading)
                LuminaTextField(
                    title: "Your question",
                    text: $draft,
                    placeholder: "How do I come across to new people?",
                    maxCharacters: 200
                )
                LuminaButton(
                    title: "Ask your chart",
                    variant: .primary,
                    isLoading: viewModel.isLoading,
                    isEnabled: !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    Task { await viewModel.ask(draft, chart: chart) }
                }
                conversationResult
            }
        }
    }

    @ViewBuilder
    var conversationResult: some View {
        switch viewModel.state {
        case .idle, .loading:
            EmptyView()
        case .answer(let text):
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text(text)
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                // This is the one surface where a language model writes the
                // words. Say so, right next to them, with a way to report it.
                AIGeneratedNote(reportedText: text)
            }
        case .failed(let error):
            conversationNote(error)
        }
    }

    @ViewBuilder
    func conversationNote(_ error: LuminaError) -> some View {
        // Missing configuration (the server has no Anthropic key yet) is a
        // "coming soon", not a scary failure — the curated answers below
        // still work either way. Key-agnostic on purpose: the free-text box
        // is only shown when the backend itself is wired up, so any
        // `.missingConfiguration` reaching here means the same thing.
        let comingSoon = error.isMissingConfiguration
        Text(comingSoon
            ? "Conversational readings are being prepared. In the meantime, the questions below are answered straight from your chart."
            : error.userBody)
            .font(LuminaTypography.bodyLight)
            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Curated (deterministic) mode

    var curated: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.md) {
            Text(viewModel.offersConversation ? "OR PICK A QUESTION" : "PICK A QUESTION")
                .font(LuminaTypography.mono)
                .tracking(1.4)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            VStack(spacing: LuminaSpacing.sm) {
                ForEach(ChartQuestion.allCases) { question in
                    questionRow(question)
                }
            }
            answerCard
        }
    }

    func questionRow(_ question: ChartQuestion) -> some View {
        Button {
            selected = question
            Haptics.selection.play()
        } label: {
            HStack {
                Text(question.rawValue)
                    .font(LuminaTypography.body)
                    .multilineTextAlignment(.leading)
                Spacer()
                if selected == question {
                    Image(systemName: "checkmark")
                        .foregroundStyle(LuminaColors.celestialBlue)
                }
            }
            .padding(LuminaSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LuminaColors.parchment)
            .luminaCornerRadius(LuminaRadii.sm)
            .overlay(
                RoundedRectangle(cornerRadius: LuminaRadii.sm, style: .continuous)
                    .stroke(
                        selected == question ? LuminaColors.celestialBlue : LuminaColors.inkBlack.opacity(0.15),
                        lineWidth: selected == question ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(question.rawValue)
        .accessibilityValue(selected == question ? "Selected" : "")
    }

    var answerCard: some View {
        LuminaCard {
            Text(ChartOracle.answer(to: selected, chart: chart))
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
