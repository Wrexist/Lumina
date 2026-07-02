import SwiftUI

/// Chart-tab entry into the daily "know your chart" quiz. Self-contained —
/// it presents `ChartQuizView` as its own sheet, so wiring it into
/// `ChartHubView` later is a single line in `astrologyContent`.
struct ChartQuizCard: View {
    let chart: NatalChart

    @State private var isPresentingQuiz = false
    @AppStorage("luminaChartQuizLastPlayedDay") private var lastPlayedDay = ""
    @AppStorage("luminaChartQuizLastScore") private var lastScore = 0
    @AppStorage("luminaChartQuizLastTotal") private var lastTotal = 0

    private var playedToday: Bool {
        lastPlayedDay == ChartQuizEngine.dayString()
    }

    var body: some View {
        Button {
            isPresentingQuiz = true
        } label: {
            cardLabel
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Know your chart? Daily quiz")
        .sheet(isPresented: $isPresentingQuiz) {
            ChartQuizView(chart: chart)
        }
    }

    private var cardLabel: some View {
        LuminaCard(surface: .glass) {
            HStack(spacing: LuminaSpacing.md) {
                Image(systemName: "sparkles")
                    .foregroundStyle(LuminaColors.mutedGold)
                VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                    Text("Know your chart?")
                        .font(LuminaTypography.heading)
                    Text("Three quick questions from your real chart — a new set each day.")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                    if playedToday {
                        Text("Today: \(lastScore) of \(lastTotal) ✦ New questions tomorrow.")
                            .font(LuminaTypography.caption)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.3))
            }
        }
    }
}

#Preview {
    ChartQuizCard(chart: BirthChartViewModel.sampleChart())
        .padding(LuminaSpacing.lg)
        .background(LuminaColors.parchment)
}
