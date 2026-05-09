import SwiftUI

/// Phase-4 chart tab. Astrology mode renders the natal wheel + Big-3 +
/// planet detail. Human Design mode (Phase 8 starter) renders the
/// bodygraph with personality-side gate activations and per-center detail.
struct ChartHubView: View {
    enum ChartMode: Hashable, CaseIterable {
        case astrology
        case humanDesign
    }

    @State private var viewModel = BirthChartViewModel()
    @State private var mode: ChartMode = .astrology
    @State private var selectedPlanet: NatalChart.PlanetPosition?
    @State private var selectedCenter: HumanDesignCenter?
    @Environment(AppRouter.self) private var router

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
        .onChange(of: router.pendingPresentation) { _, link in
            handlePending(link)
        }
        .sheet(item: $selectedPlanet) { planet in
            if case .ready(let chart) = viewModel.state {
                PlanetDetailSheet(planet: planet, chart: chart)
            }
        }
        .sheet(item: $selectedCenter) { center in
            if case .ready(let chart) = viewModel.state {
                CenterDetailSheet(center: center, activation: HumanDesignActivation.compute(from: chart))
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
            switch mode {
            case .astrology: astrologyContent(chart)
            case .humanDesign: humanDesignContent(chart)
            }
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

    // MARK: - Methods

    private func astrologyContent(_ chart: NatalChart) -> some View {
        VStack(spacing: LuminaSpacing.lg) {
            if chart.houses == nil {
                unknownTimeBanner
            }
            BigThreeBand(chart: chart)
            ChartWheelView(chart: chart, onTapPlanet: handleTap)
                .padding(LuminaSpacing.sm)
            houseSystemPicker
            AspectLegend()
            interpretationsPlaceholder
        }
    }

    private var unknownTimeBanner: some View {
        LuminaCard(surface: .glass) {
            HStack(alignment: .top, spacing: LuminaSpacing.sm) {
                Image(systemName: "clock.badge.questionmark")
                    .foregroundStyle(LuminaColors.celestialBlue)
                VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                    Text("Houses are hidden")
                        .font(LuminaTypography.body)
                        .bold()
                    Text("Without your birth time we can't compute the Ascendant, MC, or house cusps. Add a time in Settings → Your info to unlock them — your sign and planets are accurate either way.")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                }
            }
        }
    }

    private func humanDesignContent(_ chart: NatalChart) -> some View {
        let activation = HumanDesignActivation.compute(from: chart)
        return VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
            BodygraphView(activation: activation, onTapCenter: handleTapCenter)
                .frame(maxWidth: .infinity)
            definedCentersSummary(activation)
            LuminaCard {
                VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                    HStack {
                        LuminaBadge(title: "Phase 8", tone: .neutral)
                        Text("Type, Profile, and Authority")
                            .font(LuminaTypography.body)
                    }
                    Text(BodygraphView.designSideMissingNote)
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                }
            }
        }
    }

    private func definedCentersSummary(_ activation: HumanDesignActivation) -> some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
            Text("DEFINED CENTERS")
                .font(LuminaTypography.mono)
                .tracking(1.4)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            if activation.definedCenters.isEmpty {
                Text("All open — receiving and amplifying everyone around you.")
                    .font(LuminaTypography.body)
            } else {
                ForEach(Array(activation.definedCenters).sorted(by: { $0.rawValue < $1.rawValue })) { center in
                    HStack {
                        Text(center.displayName).font(LuminaTypography.body)
                        Spacer()
                        Text("\(center.gates.intersection(activation.activatedGates).count) gates")
                            .font(LuminaTypography.mono)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                    }
                }
            }
        }
    }

    private func handleTap(_ planet: NatalChart.PlanetPosition) {
        selectedPlanet = planet
    }

    private func handleTapCenter(_ center: HumanDesignCenter) {
        selectedCenter = center
    }

    private func handleRetry() {
        Task { await viewModel.reload() }
    }

    private func handleOpenSettings() {
        // TODO(lumina): present SettingsView with focus on "Your info" (Phase 12)
    }

    /// Consumes a pending `AppRouter.pendingPresentation`. We only react
    /// to chart-tab links so we don't steal sheets meant for other tabs.
    private func handlePending(_ link: LuminaDeepLink?) {
        guard let link else { return }
        switch link {
        case .chart(let planetName):
            mode = .astrology
            if let name = planetName, case .ready(let chart) = viewModel.state {
                selectedPlanet = chart.planets.first { $0.planet.caseInsensitiveCompare(name) == .orderedSame }
            }
            router.pendingPresentation = nil
        default:
            break
        }
    }
}

extension NatalChart.PlanetPosition: Identifiable {
    var id: String { planet }
}

#Preview {
    NavigationStack { ChartHubView().environment(GlossaryStore.shared) }
}
