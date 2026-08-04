import Combine
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
    @State private var selectedPlanet: ChartPlanetSelection?
    @State private var selectedCenter: ChartCenterSelection?
    @State private var pendingPlanetName: String?
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
        .task {
            await viewModel.loadIfNeeded()
            // Consume any deep link present at first appear (cold launch) and
            // resolve it now that the chart has loaded.
            consumePending(router.pendingPresentation)
            resolvePendingPlanet()
        }
        .onChange(of: router.pendingPresentation) { _, link in
            consumePending(link)
            resolvePendingPlanet()
        }
        // Birth info edited in Settings — recompute the chart (and the widget)
        // now instead of waiting for a relaunch. `loadIfNeeded()` no-ops when
        // the store revision hasn't actually moved. Mirrors TodayHubView.
        .onReceive(birthDataChanged) { _ in refresh() }
        // The selection carries its own chart. Reading `viewModel.state`
        // in here instead meant that anything moving the chart off `.ready`
        // while a sheet was up — a birth-info edit, a house-system change,
        // a pull-to-refresh — replaced the sheet's contents with nothing,
        // leaving the user staring at a blank card they had to dismiss.
        .sheet(item: $selectedPlanet) { selection in
            PlanetDetailSheet(planet: selection.planet, chart: selection.chart)
        }
        .sheet(item: $selectedCenter) { selection in
            CenterDetailSheet(
                center: selection.center,
                activation: HumanDesignActivation.compute(from: selection.chart)
            )
        }
        .toolbar {
            if case .ready(let chart) = viewModel.state, mode == .astrology {
                ToolbarItem(placement: .topBarTrailing) {
                    ChartShareButton(chart: chart)
                }
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
            body: "We need a date, time, and place to compute your chart.",
            primaryCTA: LuminaEmptyState.CTA(title: "Add birth info", action: handleOpenSettings)
        )
    }

    /// Compact "Chart settings" block at the end of the feed — switching
    /// house systems is a rare, deliberate act and shouldn't sit mid-read.
    private var houseSystemPicker: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
            Text("CHART SETTINGS")
                .font(LuminaTypography.mono)
                .tracking(1.4)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            Text("House system")
                .font(LuminaTypography.caption)
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

    /// Short tap affordance directly beneath the wheel — replaces the old
    /// standalone "interpretations" card so the tip sits where it applies.
    private var wheelCaption: some View {
        Text("Tap any planet to learn more — each reading is grounded in your exact placement, never a generic horoscope.")
            .font(LuminaTypography.caption)
            .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Methods

    /// The wheel is the hero: it follows the Big 3 immediately, with its tap
    /// caption and aspect legend attached. Identity cards come after, the
    /// "ask" CTA closes the feed, and settings sit last.
    private func astrologyContent(_ chart: NatalChart) -> some View {
        VStack(spacing: LuminaSpacing.lg) {
            if chart.houses == nil {
                unknownTimeBanner
            }
            BigThreeBand(chart: chart)
            ChartWheelView(chart: chart, onTapPlanet: handleTap)
                .padding(LuminaSpacing.sm)
            wheelCaption
            ChartDiscoveryBand(chart: chart)
            AspectLegend()
            CosmicSignatureCard(chart: chart)
            ChartStandoutCard(chart: chart)
            StrongestAspectsCard(chart: chart)
            ChartQuizCard(chart: chart)
            AskYourChartCard(chart: chart)
            houseSystemPicker
        }
        // Seeing a computed chart at all is the first Moment. `unlock` is
        // idempotent, so re-renders are free.
        .onAppear { MomentsStore.shared.unlock(.firstChart) }
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
                    Text("Without your birth time we can't compute the Ascendant, MC, or house cusps. "
                        + "Add a time in Settings → Your info to unlock them — your sign and planets are "
                        + "accurate either way.")
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
                    Text("Type, Profile and Authority")
                        .font(LuminaTypography.body)
                    Text(BodygraphView.designSideMissingNote)
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                }
            }
        }
        // Human Design is a Plus feature (README tier table). The paywall
        // names it, so it has to actually be gated — otherwise a subscriber
        // gets nothing they didn't already have.
        .premiumGated(.humanDesign)
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
        guard case .ready(let chart) = viewModel.state else { return }
        selectedPlanet = ChartPlanetSelection(planet: planet, chart: chart)
    }

    private func handleTapCenter(_ center: HumanDesignCenter) {
        guard case .ready(let chart) = viewModel.state else { return }
        selectedCenter = ChartCenterSelection(center: center, chart: chart)
    }

    private func handleRetry() {
        Task { await viewModel.reload() }
    }

    private func handleOpenSettings() {
        router.openSettings(.birthInfo)
    }

    /// Consumes a pending chart deep link. We only react to chart-tab links so
    /// we don't steal presentations meant for other tabs. The target planet
    /// name is stashed and resolved by `resolvePendingPlanet()` once the chart
    /// is `.ready` — so a link that arrives before the chart loads (cold
    /// launch) isn't dropped.
    private func consumePending(_ link: LuminaDeepLink?) {
        guard let link, case .chart(let planetName) = link else { return }
        mode = .astrology
        pendingPlanetName = planetName
        router.pendingPresentation = nil
    }

    private func resolvePendingPlanet() {
        guard let name = pendingPlanetName, case .ready(let chart) = viewModel.state else { return }
        let match = chart.planets.first { $0.planet.caseInsensitiveCompare(name) == .orderedSame }
        selectedPlanet = match.map { ChartPlanetSelection(planet: $0, chart: chart) }
        pendingPlanetName = nil
    }
}

// A plain extension (SwiftLint bans `private extension`) keeps the freshness
// plumbing out of the view's type body while members stay `private`.
extension ChartHubView {
    /// Birth info saved or cleared in Settings (or sign-out). Mapped to `Void`
    /// off the notification before hopping to the main queue so no non-Sendable
    /// `Notification` crosses an isolation boundary.
    private var birthDataChanged: AnyPublisher<Void, Never> {
        NotificationCenter.default.publisher(for: UserBirthDataStore.didChangeNotification)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private func refresh() {
        Task { await viewModel.loadIfNeeded() }
    }
}

extension NatalChart.PlanetPosition: Identifiable {
    var id: String { planet }
}

/// A sheet presentation pins the chart it was opened against, so the sheet
/// keeps rendering the data the user tapped even if the view model reloads
/// underneath it.
struct ChartPlanetSelection: Identifiable {
    let planet: NatalChart.PlanetPosition
    let chart: NatalChart

    var id: String { planet.id }
}

struct ChartCenterSelection: Identifiable {
    let center: HumanDesignCenter
    let chart: NatalChart

    var id: String { center.id }
}

#Preview {
    NavigationStack { ChartHubView().environment(GlossaryStore.shared) }
        .environment(AppRouter(storage: .inMemory()))
}
