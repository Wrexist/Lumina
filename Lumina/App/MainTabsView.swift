import SwiftUI

/// The 5-tab spine. Each tab gets its own `NavigationStack` so cross-tab
/// jumps don't pollute back history. Settings is intentionally not a sixth
/// tab — it surfaces from a top-trailing gear in every hub (Phase 12).
struct MainTabsView: View {
    @Bindable var router: AppRouter
    @State private var settingsPresented = false
    @State private var helpPresented = false
    @Bindable private var paywallPresenter = PaywallPresenter.shared
    @State private var purchaseInFlight = false
    @State private var purchaseError: LuminaError?

    var body: some View {
        TabView(selection: $router.selectedTab) {
            ForEach(LuminaTab.visible, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .tag(tab)
            }
        }
        .tint(LuminaColors.celestialBlue)
        .environment(router)
        .sheet(isPresented: $settingsPresented) {
            SettingsView()
        }
        .sheet(isPresented: $helpPresented) {
            NavigationStack { HelpView() }
        }
        // The single global paywall host. Any locked surface anywhere in the
        // app calls `PaywallPresenter.shared.present(for:)` and it comes up
        // here — so the purchase is reachable from everywhere, not just the
        // one-shot during onboarding.
        .fullScreenCover(isPresented: $paywallPresenter.isPresented) {
            PaywallOfferView(
                variant: .initial,
                triggeringFeature: paywallPresenter.pendingFeature,
                purchaseInFlight: purchaseInFlight,
                purchaseError: purchaseError,
                onStartTrial: handleUpgrade,
                onContinueFree: { paywallPresenter.dismiss() }
            )
        }
        .task { consumeGlobal(router.pendingPresentation) }
        .onChange(of: router.pendingPresentation) { _, link in
            consumeGlobal(link)
        }
    }

    /// Runs an upgrade started from anywhere in the app. Mirrors the
    /// onboarding path: keep the cover up until the purchase resolves, and
    /// surface real failures rather than silently dropping the user back.
    private func handleUpgrade(_ plan: IAPManager.PremiumPlan) {
        purchaseInFlight = true
        purchaseError = nil
        Task {
            defer { purchaseInFlight = false }
            do {
                _ = try await IAPManager.shared.purchase(plan: plan)
                paywallPresenter.dismiss()
            } catch {
                purchaseError = LuminaError.from(error)
            }
        }
    }

    /// Presents shell-level destinations (Settings, Help) that sit above a tab
    /// rather than inside one. Tab-specific links are consumed by their hub.
    private func consumeGlobal(_ link: LuminaDeepLink?) {
        switch link {
        case .settings:
            settingsPresented = true
            router.pendingPresentation = nil
        case .help:
            helpPresented = true
            router.pendingPresentation = nil
        default:
            break
        }
    }

    @ViewBuilder
    private func tabContent(for tab: LuminaTab) -> some View {
        NavigationStack {
            Group {
                switch tab {
                case .today: TodayHubView()
                case .chart: ChartHubView()
                case .palm: PalmHubView()
                case .people: PeopleHubView()
                case .reflect: ReflectHubView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        settingsPresented = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var router = AppRouter(storage: .inMemory())
    return MainTabsView(router: router)
        .environment(GlossaryStore.shared)
}
