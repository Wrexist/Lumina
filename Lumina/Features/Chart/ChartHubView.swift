import SwiftUI

/// Phase-4 chart tab. Shows the user's real natal chart by default and
/// falls through to a deterministic sample chart on dev builds without
/// the Swiss Eph URL configured (see `BirthChartViewModel.sampleChart`).
///
/// Astrology / Human Design toggle stays in place for Phase 8.
struct ChartHubView: View {
    enum ChartMode: Hashable, CaseIterable {
        case astrology
        case humanDesign
    }

    @State private var viewModel = BirthChartViewModel()
    @State private var mode: ChartMode = .astrology
    @State private var selectedPlanet: NatalChart.PlanetPosition?

    var body: some View {
        ScrollView {
            VStack(spacing: LuminaSpacing.lg) {
                modePicker
                content
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle("Chart")
        .task { await viewModel.loadIfNeeded() }
        .sheet(item: $selectedPlanet) { planet in
            if case .ready(let chart) = viewModel.state {
                PlanetDetailSheet(planet: planet, chart: chart)
            }
        }
    }

    private var modePicker: some View {
        LuminaSegmentedControl(
            options: [
                (ChartMode.astrology, "Astrology"),
                (ChartMode.humanDesign, "Human Design"),
            ],
            selection: $mode
        )
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingState
        case .ready(let chart):
            chartContent(chart)
        case .missingBirthData:
            missingDataState
        case .failed(let error):
            LuminaErrorState(error: error, onRetry: handleRetry)
        }
    }

    private var loadingState: some View {
        VStack(spacing: LuminaSpacing.md) {
            LuminaSkeleton(shape: .block(height: 96))
            LuminaSkeleton(shape: .block(height: 320))
            LuminaSkeleton(shape: .line(height: 18))
            LuminaSkeleton(shape: .line(height: 18))
        }
    }

    private var missingDataState: some View {
        LuminaEmptyState(
            systemImage: "circle.dotted",
            title: "Add your birth info",
            body: "We need a date, time, and place to compute your chart. Open Settings → Your info to add them.",
            primaryCTA: LuminaEmptyState.CTA(title: "Open Settings", action: handleOpenSettings)
        )
    }

    private var houseSystemPicker: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
            Text("HOUSE SYSTEM")
                .font(LuminaTypography.mono)
                .tracking(1.4)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            LuminaSegmentedControl(
                options: [
                    (HouseSystem.placidus, "Placidus"),
                    (HouseSystem.wholeSign, "Whole-sign"),
                    (HouseSystem.sidereal, "Sidereal"),
                ],
                selection: Binding(
                    get: { viewModel.houseSystem },
                    set: { newValue in
                        viewModel.houseSystem = newValue
                        Task { await viewModel.reload() }
                    }
                )
            )
        }
    }

    private var interpretationsPlaceholder: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("Tap any planet to learn more")
                    .font(LuminaTypography.heading)
                Text("Phase 5 of the roadmap wires the RAG-backed interpretations under each planet, the Big 3, and the aspect lines.")
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
        }
    }

    // MARK: - Actions

    private func chartContent(_ chart: NatalChart) -> some View {
        VStack(spacing: LuminaSpacing.lg) {
            BigThreeBand(chart: chart)
            ChartWheelView(chart: chart, onTapPlanet: handleTap)
                .padding(LuminaSpacing.sm)
            houseSystemPicker
            interpretationsPlaceholder
        }
    }

    private func handleTap(_ planet: NatalChart.PlanetPosition) {
        selectedPlanet = planet
    }

    private func handleRetry() {
        Task { await viewModel.reload() }
    }

    private func handleOpenSettings() {
        // TODO(lumina): present SettingsView with focus on "Your info" (Phase 12)
    }
}

extension NatalChart.PlanetPosition: Identifiable {
    var id: String { planet }
}

#Preview {
    NavigationStack { ChartHubView().environment(GlossaryStore.shared) }
}
