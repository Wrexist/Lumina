import SwiftUI

/// Phase-3 Today (Home) hub. Real Big-3 band off the user's natal chart,
/// today's deterministic headline, the "what's happening" trio, and a
/// quick-actions row that deep-links into the other tabs via `AppRouter`.
///
/// The audio-narrated reading body itself lands once the Anthropic +
/// ElevenLabs keys are wired (Phase 5). Until then, the reading card
/// shows a clearly-labelled "coming soon" affordance instead of stub
/// reading text.
struct TodayHubView: View {
    @State private var viewModel = TodayViewModel()
    @Environment(AppRouter.self) private var router
    @ScaledMetric private var iconSize: CGFloat = 28
    @State private var showingWhy = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                header
                content
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle("Today")
        .task { await viewModel.loadIfNeeded() }
        .sheet(isPresented: $showingWhy) {
            TodayTransparencySheet(transits: viewModel.transits)
        }
    }

    // MARK: - View building blocks

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingState
        case .missingBirthData:
            missingDataState
        case .failed(let error):
            LuminaErrorState(error: error, onRetry: handleRetry)
        case .ready:
            loadedContent
        }
    }

    private var loadedContent: some View {
        let lines = viewModel.todayLines
        return VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
            if let chart = viewModel.natalChart {
                BigThreeBand(chart: chart)
            }
            headlineCard(lines.headline)
            dailyReadingCard
            MoonPhaseCard()
            RetrogradeCard()
            ProgressedChapterCard()
            WhatsComingCard()
            ReturnsCard()
            if !lines.secondary.isEmpty {
                Divider()
                whatsHappeningSection(lines.secondary)
                LuminaButton(title: "Why these?", variant: .ghost) { showingWhy = true }
            }
            Divider()
            quickActionsSection
        }
    }

    private var loadingState: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.md) {
            LuminaSkeleton(shape: .block(height: 96))
            LuminaSkeleton(shape: .line(width: 260, height: 22))
            LuminaSkeleton(shape: .block(height: 80))
            LuminaSkeleton(shape: .line(height: 18))
            LuminaSkeleton(shape: .line(height: 18))
        }
    }

    private var missingDataState: some View {
        LuminaEmptyState(
            systemImage: "sparkles",
            title: "Finish your chart",
            body: "Add your birth date, time, and place to see your sky today.",
            primaryCTA: LuminaEmptyState.CTA(title: "Add birth info", action: openSettings)
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
            Text(dateLabel.uppercased())
                .font(LuminaTypography.mono)
                .tracking(1.4)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            Text("Your sky today")
                .font(LuminaTypography.display)
        }
    }

    private func headlineCard(_ headline: String?) -> some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text(headline ?? "A quiet sky today — nothing major is touching your chart right now.")
                    .font(LuminaTypography.heading)
                Text("Tap any planet on the Chart tab to learn more about your placements.")
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
        }
    }

    private var dailyReadingCard: some View {
        let reading = DailyReading.compose(from: viewModel.transits)
        return LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                HStack(spacing: LuminaSpacing.sm) {
                    Text("Your reading")
                        .font(LuminaTypography.heading)
                    Spacer()
                    DailyReadingShareButton(reading: reading, date: .now)
                    LuminaBadge(title: "Audio soon", tone: .neutral)
                }
                Text(reading)
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func whatsHappeningSection(_ lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
            Text("WHAT'S HAPPENING")
                .font(LuminaTypography.mono)
                .tracking(1.4)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            ForEach(lines, id: \.self) { line in
                HStack(alignment: .top, spacing: LuminaSpacing.sm) {
                    Text("•").font(LuminaTypography.body)
                    Text(line).font(LuminaTypography.body)
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
            Text("QUICK ACTIONS")
                .font(LuminaTypography.mono)
                .tracking(1.4)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LuminaSpacing.md) {
                    quickAction("See chart", systemImage: "circle.dotted") { jump(to: .chart) }
                    quickAction("Reflect", systemImage: "moonphase.first.quarter") { jump(to: .reflect) }
                    quickAction("Add a friend", systemImage: "person.2.badge.plus") { jump(to: .people) }
                    quickAction("Scan a hand", systemImage: "hand.raised") { jump(to: .palm) }
                }
            }
        }
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE · MMM d"
        return formatter.string(from: .now)
    }

    // MARK: - Methods

    private func quickAction(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            LuminaCard(padding: LuminaSpacing.md) {
                VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                    Image(systemName: systemImage)
                        .font(.system(size: iconSize, weight: .light))
                        .foregroundStyle(LuminaColors.celestialBlue)
                    Text(title).font(LuminaTypography.body)
                }
                .frame(width: 140, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private func jump(to tab: LuminaTab) {
        Haptics.light.play()
        router.selectedTab = tab
    }

    private func handleRetry() {
        Task { await viewModel.retry() }
    }

    private func openSettings() {
        router.handle(deepLink: .settings)
    }
}

#Preview {
    NavigationStack { TodayHubView() }
        .environment(AppRouter(storage: .inMemory()))
        .environment(GlossaryStore.shared)
}
