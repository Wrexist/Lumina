import SwiftUI

/// The daily "know your chart" mini-game sheet. Three questions generated
/// deterministically from the real chart via the daily seed — the same set
/// all day, a fresh set tomorrow. One play per day; replaying to grind would
/// teach the quiz to feel like a slot machine, which is off-brand (see
/// `docs/NAVIGATION.md` §13 — the brand stays quiet).
struct ChartQuizView: View {
    let chart: NatalChart

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var preferences = AppPreferences.shared
    @State private var questions: [ChartQuizQuestion] = []
    @State private var currentIndex = 0
    @State private var selectedIndex: Int?
    @State private var correctCount = 0
    @State private var isFinished = false
    @State private var hasPrepared = false
    @ScaledMetric private var sparkleSize: CGFloat = 44
    @AppStorage("luminaChartQuizLastPlayedDay") private var lastPlayedDay = ""
    @AppStorage("luminaChartQuizLastScore") private var lastScore = 0
    @AppStorage("luminaChartQuizLastTotal") private var lastTotal = 0

    private var reduceMotion: Bool {
        LuminaMotion.isReduced(system: systemReduceMotion, appOverride: preferences.reduceMotionOverride)
    }

    private var playedToday: Bool {
        lastPlayedDay == ChartQuizEngine.dayString()
    }

    private var currentQuestion: ChartQuizQuestion? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                content
                    .padding(LuminaSpacing.lg)
            }
            .background(LuminaColors.parchment)
            .navigationTitle("Know your chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear(perform: prepare)
    }

    @ViewBuilder
    private var content: some View {
        // `playedToday` also flips mid-run (the first answer records the day so
        // an abandoned run still counts), so it can't gate the live quiz — an
        // in-progress session always has questions loaded. Only a fresh open on
        // an already-played day (no questions prepared) or a finished run shows
        // the end state.
        if isFinished || (playedToday && questions.isEmpty) {
            endState
        } else if let question = currentQuestion {
            questionView(question)
        } else if hasPrepared {
            emptyState
        } else {
            loadingPlaceholder
        }
    }

    // MARK: - Question flow

    private func questionView(_ question: ChartQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
            Text("QUESTION \(currentIndex + 1) OF \(questions.count)")
                .font(LuminaTypography.mono)
                .tracking(1.4)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            Text(question.prompt)
                .font(LuminaTypography.heading)
            VStack(spacing: LuminaSpacing.sm) {
                ForEach(question.options.indices, id: \.self) { index in
                    optionRow(index, question: question)
                }
            }
            if selectedIndex != nil {
                insightBlock(question)
                    .transition(reduceMotion ? .identity : .opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func optionRow(_ index: Int, question: ChartQuizQuestion) -> some View {
        Button {
            select(index, question: question)
        } label: {
            HStack(spacing: LuminaSpacing.sm) {
                Text(question.options[index])
                    .font(LuminaTypography.body)
                    .multilineTextAlignment(.leading)
                Spacer()
                if let icon = resultIcon(for: index, question: question) {
                    Image(systemName: icon)
                        .foregroundStyle(index == question.answerIndex ? LuminaColors.mutedGold : LuminaColors.error)
                }
            }
            .padding(LuminaSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowFill(for: index, question: question))
            .luminaCornerRadius(LuminaRadii.md)
            .overlay(
                RoundedRectangle(cornerRadius: LuminaRadii.md, style: .continuous)
                    .stroke(rowStroke(for: index, question: question), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(selectedIndex != nil)
    }

    private func insightBlock(_ question: ChartQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.md) {
            Text(question.insight)
                .font(LuminaTypography.bodyLight)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            LuminaButton(
                title: currentIndex + 1 < questions.count ? "Next" : "See your score",
                variant: .ghost,
                action: advance
            )
        }
    }

    // MARK: - End states

    private var endState: some View {
        VStack(spacing: LuminaSpacing.lg) {
            Image(systemName: "sparkles")
                .font(.system(size: sparkleSize))
                .foregroundStyle(LuminaColors.mutedGold)
            Text("\(lastScore) of \(lastTotal)")
                .font(LuminaTypography.display)
            Text(ChartQuizEngine.verdict(correct: lastScore, total: lastTotal))
                .font(LuminaTypography.body)
                .multilineTextAlignment(.center)
            if !isFinished {
                Text("Come back tomorrow — the sky will have new questions.")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            LuminaButton(title: "Done", variant: .secondary) { dismiss() }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, LuminaSpacing.xl)
    }

    private var emptyState: some View {
        LuminaEmptyState(
            systemImage: "sparkles",
            title: "No questions yet",
            body: "Your chart doesn't have enough detail for questions yet.",
            primaryCTA: LuminaEmptyState.CTA(title: "Done") { dismiss() }
        )
    }

    /// Mirrors `questionView`'s layout (kicker → prompt → three option rows) so
    /// the real content reveals in place without reflowing (`docs/NAVIGATION.md`
    /// §4).
    private var loadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
            LuminaSkeleton(shape: .line(width: 140, height: 12))
            LuminaSkeleton(shape: .line(height: 28))
            VStack(spacing: LuminaSpacing.sm) {
                ForEach(0..<3, id: \.self) { _ in
                    LuminaSkeleton(shape: .block(height: 52))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Methods

    /// Builds today's questions unless the user already played — the
    /// once-a-day rhythm *is* the game.
    private func prepare() {
        hasPrepared = true
        guard !playedToday else { return }
        questions = ChartQuizEngine.questions(from: chart, seed: ChartQuizEngine.dailySeed())
    }

    private func select(_ index: Int, question: ChartQuizQuestion) {
        guard selectedIndex == nil else { return }
        if reduceMotion {
            selectedIndex = index
        } else {
            withAnimation(.smooth(duration: 0.25)) { selectedIndex = index }
        }
        if index == question.answerIndex {
            correctCount += 1
            Haptics.success.play()
        } else {
            Haptics.warning.play()
        }
        // Record play on the first answer so abandoning mid-run still counts —
        // the one-play-a-day rhythm holds even if the sheet is dismissed before
        // the last question. `finish()` finalizes the same values on completion.
        lastPlayedDay = ChartQuizEngine.dayString()
        lastScore = correctCount
        lastTotal = questions.count
    }

    private func advance() {
        guard currentIndex + 1 < questions.count else {
            finish()
            return
        }
        if reduceMotion {
            stepForward()
        } else {
            withAnimation(.smooth(duration: 0.25)) { stepForward() }
        }
    }

    private func stepForward() {
        currentIndex += 1
        selectedIndex = nil
    }

    /// Records today's play so reopening the sheet shows the end state —
    /// new questions arrive with tomorrow's seed, not with a replay.
    private func finish() {
        lastPlayedDay = ChartQuizEngine.dayString()
        lastScore = correctCount
        lastTotal = questions.count
        isFinished = true
    }

    private func rowFill(for index: Int, question: ChartQuizQuestion) -> Color {
        guard let selectedIndex else { return LuminaColors.parchment }
        if index == question.answerIndex { return LuminaColors.mutedGold.opacity(0.25) }
        if index == selectedIndex { return LuminaColors.error.opacity(0.12) }
        return LuminaColors.parchment
    }

    private func rowStroke(for index: Int, question: ChartQuizQuestion) -> Color {
        guard let selectedIndex else { return LuminaColors.inkBlack.opacity(0.15) }
        if index == question.answerIndex { return LuminaColors.mutedGold }
        if index == selectedIndex { return LuminaColors.error }
        return LuminaColors.inkBlack.opacity(0.08)
    }

    private func resultIcon(for index: Int, question: ChartQuizQuestion) -> String? {
        guard let selectedIndex else { return nil }
        if index == question.answerIndex { return "checkmark.circle.fill" }
        if index == selectedIndex { return "xmark.circle" }
        return nil
    }
}

#Preview {
    ChartQuizView(chart: BirthChartViewModel.sampleChart())
}
