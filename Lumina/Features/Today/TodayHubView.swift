import Combine
import SwiftUI

/// The Today (Home) hub, restructured for signal over noise:
/// hero → Big-3 band → reading card (headline + body, extra transits behind
/// "Details") → sky-context strip (Moon + retrogrades) → "Ahead" card → quick
/// actions. The progressed "chapter" card joins only around a progressed-Moon
/// sign change, else sits below the quick actions. All data comes from one
/// `TodayViewModel` fan-out, so the secondary cards reveal together over
/// fixed-height skeletons instead of popping in.
struct TodayHubView: View {
    @State private var viewModel = TodayViewModel()
    @Environment(AppRouter.self) private var router
    @ScaledMetric private var iconSize: CGFloat = 28
    @State private var showingWhy = false

    // Daily reveal — the reading starts veiled on the first visit of each
    // calendar day and is unveiled by a tap (happy path only; see
    // `readingSection`).
    @State private var reveal = DailyRevealState()
    @State private var moments = MomentsStore.shared
    /// Set on an unveil that lands while the sky context is still loading,
    /// so the strip's arrival gets one gentle tick (see `body`'s onChange).
    @State private var pendingSkyContextHaptic = false
    @State private var preferences = AppPreferences.shared
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.scenePhase) private var scenePhase
    /// The current calendar day as a stable key. Bumped when the day rolls
    /// over (foreground midnight, or returning to an app left open past
    /// midnight), so the reading section re-veils instead of lingering
    /// unveiled from yesterday.
    @State private var revealDayKey = DailyRevealState.dayKey(for: .now)

    private var reduceMotion: Bool {
        LuminaMotion.isReduced(system: systemReduceMotion, appOverride: preferences.reduceMotionOverride)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                CelestialHeroCard(date: .now)
                content
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadIfNeeded() }
        // Freshness triggers: the calendar day rolling over in a long-lived
        // process, and birth info edited in Settings. `loadIfNeeded()` no-ops
        // when neither has actually moved.
        .onReceive(dayChanged) { _ in
            revealDayKey = DailyRevealState.dayKey(for: .now)
            refresh()
        }
        .onReceive(birthDataChanged) { _ in refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { revealDayKey = DailyRevealState.dayKey(for: .now) }
        }
        .onChange(of: viewModel.skyContextLoading) { _, isLoading in
            skyContextLoadingChanged(isLoading: isLoading)
        }
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
        VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
            if let chart = viewModel.natalChart {
                BigThreeBand(chart: chart)
            }
            // A freshly unlocked Moment surfaces once, dismissible, and
            // never interrupts the reveal ritual below it.
            if let moment = moments.latestUnseen {
                MomentUnlockCard(moment: moment) {
                    moments.markSeen(moment)
                }
            }
            if viewModel.transitsUnavailable {
                transitsUnavailableCard
            } else {
                readingSection
                    .id(revealDayKey)
            }
            skyContextSection
            aheadSection
            if let progressions = viewModel.progressions, viewModel.chapterIsTimely {
                ProgressedChapterCard(result: progressions)
            }
            Divider()
            quickActionsSection
            if let progressions = viewModel.progressions, !viewModel.chapterIsTimely {
                ProgressedChapterCard(result: progressions)
            }
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

    /// The reading slot for the happy path: veiled on the first visit of
    /// each calendar day, the real card afterwards. Only `.ready` with
    /// transits ever goes through here — the transits-unavailable card is
    /// never veiled (an error is not a gift box), and loading /
    /// missing-birth-data / failed states are untouched (see `content`).
    @ViewBuilder
    private var readingSection: some View {
        if reveal.isRevealedToday {
            readingCard
                .transition(reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.97)))
        } else {
            DailyRevealVeilCard(onUnveil: unveil)
                .transition(reduceMotion ? .identity : .opacity)
        }
    }

    /// The hero reading — headline as the title line, grounded body below,
    /// and the remaining transits collapsed behind "Details". The "Why
    /// these?" transparency control lives in the header, so it stays
    /// reachable even when only one transit (or none) is active.
    private var readingCard: some View {
        let lines = viewModel.todayLines
        return LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                HStack(alignment: .firstTextBaseline, spacing: LuminaSpacing.md) {
                    Text(lines.headline ?? "A quiet sky today")
                        .font(LuminaTypography.heading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    whyTheseButton
                    DailyReadingShareButton(
                        reading: DailyReading.compose(from: viewModel.transits),
                        date: .now
                    )
                }
                Text(DailyReading.bodyText(from: viewModel.transits))
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !lines.secondary.isEmpty {
                    detailsDisclosure(lines.secondary)
                }
            }
        }
    }

    /// Rendered when the transit fetch itself failed. Never the quiet-sky
    /// copy — affirming a calm sky we couldn't actually read would be
    /// invented content.
    private var transitsUnavailableCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("Couldn't read today's sky")
                    .font(LuminaTypography.heading)
                Text("Your reading is grounded in the real transits, and we couldn't fetch them just now.")
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                LuminaButton(
                    title: "Retry",
                    variant: .ghost,
                    systemImage: "arrow.clockwise",
                    isLoading: viewModel.transitsRetrying
                ) {
                    Task { await viewModel.retryTransits() }
                }
            }
        }
    }

    private var whyTheseButton: some View {
        Button {
            showingWhy = true
        } label: {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(LuminaColors.celestialBlue)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Why these?")
        .accessibilityHint("Shows the exact transits behind today's reading")
    }

    private func detailsDisclosure(_ lines: [String]) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                ForEach(lines, id: \.self) { line in
                    HStack(alignment: .top, spacing: LuminaSpacing.sm) {
                        Text("•").font(LuminaTypography.body)
                        Text(line).font(LuminaTypography.body)
                    }
                }
            }
            .padding(.top, LuminaSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text("Details")
                .font(LuminaTypography.caption)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
        }
        .tint(LuminaColors.inkBlack.opacity(0.6))
    }

    /// Moon + retrogrades — the sky-context strip under the reading.
    /// Fixed-height skeletons hold the layout until the whole fan-out
    /// resolves, so the cards reveal together with no reflow.
    @ViewBuilder
    private var skyContextSection: some View {
        if viewModel.skyContextLoading {
            LuminaSkeleton(shape: .block(height: 150))
            LuminaSkeleton(shape: .block(height: 64))
        } else {
            if let moon = viewModel.moonPhase {
                MoonPhaseCard(phase: moon)
            }
            if let retro = viewModel.retrogrades {
                if retro.planets.contains(where: \.isRetrograde) {
                    RetrogradeCard(result: retro)
                } else { noRetrogradesCard }
            }
        }
    }

    /// The "Ahead" card — imminent return (when there is one) + forecast.
    @ViewBuilder
    private var aheadSection: some View {
        if viewModel.skyContextLoading {
            LuminaSkeleton(shape: .block(height: 88))
        } else {
            WhatsComingCard(imminentReturns: viewModel.imminentReturns)
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
                    momentsQuickAction
                }
            }
        }
    }
}

// MARK: - Methods
// A plain extension (SwiftLint bans `private extension`) so the view's
// type body stays inside the length limit; members stay `private`.
extension TodayHubView {
    private func quickAction(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            quickActionTile(title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    /// The tile face shared by the tab-jump quick actions and the Moments
    /// NavigationLink, so both keep the row's rhythm.
    private func quickActionTile(_ title: String, systemImage: String) -> some View {
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

    private var noRetrogradesCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                Text("RETROGRADES")
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                Text("No retrogrades right now — all planets are direct.")
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
        }
    }
    /// Moments has no tab of its own — this NavigationLink is its persistent
    /// home in the main flow (it was previously buried in Settings).
    private var momentsQuickAction: some View {
        NavigationLink {
            MomentsView()
        } label: {
            quickActionTile("Moments", systemImage: "sparkles")
        }
        .buttonStyle(.plain)
    }

    /// Midnight rollover, mapped to `Void` before hopping to the main queue
    /// so no non-Sendable `Notification` crosses an isolation boundary.
    private var dayChanged: AnyPublisher<Void, Never> {
        NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Birth info saved or cleared (Settings → "Update birth info", sign-out).
    private var birthDataChanged: AnyPublisher<Void, Never> {
        NotificationCenter.default.publisher(for: UserBirthDataStore.didChangeNotification)
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private func refresh() {
        Task { await viewModel.loadIfNeeded() }
    }

    /// Unveils today's reading: one success haptic, then the reading
    /// transitions in — instantly (no animation) under Reduce Motion.
    private func unveil() {
        Haptics.success.play()
        if viewModel.skyContextLoading {
            pendingSkyContextHaptic = true
        }
        if reduceMotion {
            reveal.markRevealed()
        } else {
            withAnimation(.smooth(duration: 0.4)) {
                reveal.markRevealed()
            }
        }
    }

    /// One-time gentle tick when the sky-context strip finishes loading
    /// *after* a reveal tap — the rest of the page arriving is part of the
    /// payoff. `Haptics` itself no-ops under Reduce Motion.
    private func skyContextLoadingChanged(isLoading: Bool) {
        guard !isLoading, pendingSkyContextHaptic else { return }
        pendingSkyContextHaptic = false
        Haptics.light.play()
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
