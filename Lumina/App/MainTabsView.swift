import SwiftUI

/// The 5-tab spine. Each tab gets its own `NavigationStack` so cross-tab
/// jumps don't pollute back history. Settings is intentionally not a sixth
/// tab — it surfaces from a top-trailing gear in every hub (Phase 12).
struct MainTabsView: View {
    @Bindable var router: AppRouter
    @State private var settingsPresented = false
    @State private var helpPresented = false

    var body: some View {
        TabView(selection: $router.selectedTab) {
            ForEach(LuminaTab.allCases, id: \.self) { tab in
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
        .task { consumeGlobal(router.pendingPresentation) }
        .onChange(of: router.pendingPresentation) { _, link in
            consumeGlobal(link)
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
