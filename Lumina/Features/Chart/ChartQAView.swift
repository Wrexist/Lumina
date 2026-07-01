import SwiftUI

/// "Ask your chart" — the deterministic, grounded version. The user taps a
/// curated question; the answer is read straight from their real chart via
/// `ChartOracle`. Pushed from the Chart tab. A free-text, language-model
/// version layers on later (needs the backend reading endpoint), but the
/// honest, unblocked experience ships now.
struct ChartQAView: View {
    let chart: NatalChart
    @State private var selected: ChartQuestion = .bigThree

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                Text("Tap a question — every answer is read straight from your chart, never a generic horoscope.")
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))

                VStack(spacing: LuminaSpacing.sm) {
                    ForEach(ChartQuestion.allCases) { question in
                        questionRow(question)
                    }
                }

                answerCard
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle("Ask your chart")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func questionRow(_ question: ChartQuestion) -> some View {
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

    private var answerCard: some View {
        LuminaCard {
            Text(ChartOracle.answer(to: selected, chart: chart))
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
