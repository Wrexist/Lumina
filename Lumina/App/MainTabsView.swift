import SwiftUI

/// The 5-tab spine. Each tab gets its own `NavigationStack` so cross-tab
/// jumps don't pollute back history. Settings is intentionally not a sixth
/// tab — it surfaces from a top-trailing gear in every hub (Phase 12).
struct MainTabsView: View {
    @Bindable var router: AppRouter
    @State private var settingsPresented = false

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
        .sheet(isPresented: $settingsPresented) {
            SettingsView()
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
