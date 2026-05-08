import SwiftUI

/// Root scene switch. Owns the `AppRouter` and routes between the three
/// stages: launching splash, onboarding (full-screen cover), and the main
/// 5-tab shell. See `docs/NAVIGATION.md` §2.3.
struct RootView: View {
    @State private var router = AppRouter()
    @State private var glossary = GlossaryStore.shared

    var body: some View {
        Group {
            switch router.stage {
            case .launching:
                LaunchSplashView()
                    .task {
                        glossary.loadIfNeeded()
                        // Tiny settle so we don't strobe on a fast cold launch.
                        try? await Task.sleep(for: .milliseconds(250))
                        router.bootstrap()
                    }
            case .onboarding:
                OnboardingPlaceholderView {
                    router.completeOnboarding()
                }
            case .mainTabs:
                MainTabsView(router: router)
            }
        }
        .environment(glossary)
        .onOpenURL { url in
            if let link = LuminaDeepLink.from(url: url) {
                router.handle(deepLink: link)
            }
        }
    }
}

private struct LaunchSplashView: View {
    var body: some View {
        ZStack {
            LuminaColors.parchment.ignoresSafeArea()
            VStack(spacing: LuminaSpacing.md) {
                Text("Lumina")
                    .font(LuminaTypography.display)
                    .foregroundStyle(LuminaColors.inkBlack)
                Text("Finally, a real one.")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.celestialBlue)
            }
        }
    }
}

#Preview {
    RootView()
}
