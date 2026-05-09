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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                header
                if let chart = viewModel.natalChart {
                    BigThreeBand(chart: chart)
                }
                headlineCard
                readingPlaceholder
                Divider()
                whatsHappeningSection
                Divider()
                quickActionsSection
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle("Today")
        .task { await viewModel.loadIfNeeded() }
    }

    // MARK: - View building blocks

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

    private var headlineCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text(TodayViewModel.headline(for: .now))
                    .font(LuminaTypography.heading)
                Text("Tap any planet on the Chart tab to learn more about your placements.")
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
        }
    }

    private var readingPlaceholder: some View {
        LuminaCard(surface: .glass) {
            HStack(spacing: LuminaSpacing.md) {
                Image(systemName: "headphones")
                    .font(.system(size: 28))
                    .foregroundStyle(LuminaColors.celestialBlue)
                VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                    HStack(spacing: LuminaSpacing.sm) {
                        LuminaBadge(title: "Soon", tone: .neutral)
                        Text("Today's reading, narrated")
                            .font(LuminaTypography.body)
                    }
                    Text("Lands with the Anthropic + ElevenLabs wire-up in Phase 5.")
                        .font(LuminaTypography.caption)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                }
            }
        }
    }

    private var whatsHappeningSection: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
            Text("WHAT'S HAPPENING")
                .font(LuminaTypography.mono)
                .tracking(1.4)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            ForEach(TodayViewModel.whatsHappening(for: .now), id: \.self) { line in
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
                        .font(.system(size: 28, weight: .light))
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
}

#Preview {
    NavigationStack { TodayHubView() }
        .environment(AppRouter(storage: .inMemory()))
        .environment(GlossaryStore.shared)
}
