import Foundation
import OSLog
import SwiftUI

/// Root navigation state machine. A user is in exactly one of the cases of
/// `Stage`, and `selectedTab` is meaningful only when `.mainTabs` is active.
///
/// See `docs/NAVIGATION.md` §2 — onboarding is its own root scene; the
/// 5-tab `MainTabsView` only appears after `OnboardingState.complete` has
/// been written.
@MainActor
@Observable
final class AppRouter {
    enum Stage: Equatable, Sendable {
        case launching
        case onboarding
        case mainTabs
    }

    private let logger = Logger(subsystem: "app.lumina.ios", category: "AppRouter")
    private let storage: AppRouterStorage

    var stage: Stage
    var selectedTab: LuminaTab {
        didSet {
            guard oldValue != selectedTab else { return }
            storage.lastSelectedTab = selectedTab
        }
    }

    /// Inbound deep link captured before the user finished onboarding. The
    /// shell consumes and clears this on the first transition to `.mainTabs`.
    var pendingDeepLink: LuminaDeepLink?

    /// Inbound deep link the active tab should present (e.g. open the planet
    /// detail sheet on the Chart tab). Cleared by the consumer.
    var pendingPresentation: LuminaDeepLink?

    /// `true` while the user is mid-onboarding *or* the app is on its first
    /// cold launch and we haven't yet decided where to land. Bind from
    /// `LuminaApp` to drive the root `WindowGroup`.
    init(storage: AppRouterStorage = .userDefaults) {
        self.storage = storage
        self.selectedTab = storage.lastSelectedTab
        if storage.hasCompletedOnboarding {
            self.stage = .mainTabs
        } else {
            self.stage = .launching
        }
    }

    /// Called from `LuminaApp` after the splash settle so we don't flash
    /// onboarding for a returning user on a slow cold launch.
    func bootstrap() {
        switch stage {
        case .launching:
            if storage.hasCompletedOnboarding {
                stage = .mainTabs
                replayPendingDeepLinkIfNeeded()
            } else {
                stage = .onboarding
            }
        case .onboarding, .mainTabs:
            return
        }
    }

    /// Marks onboarding as complete and routes the user to `Today`. The
    /// onboarding flow can never be re-entered; users edit birth info via
    /// Settings → "Update birth info" instead.
    func completeOnboarding() {
        storage.hasCompletedOnboarding = true
        selectedTab = .today
        stage = .mainTabs
        replayPendingDeepLinkIfNeeded()
    }

    /// Replays a deep link that arrived before the shell was ready (during the
    /// splash or mid-onboarding) so it isn't silently dropped on the
    /// transition to `.mainTabs`.
    private func replayPendingDeepLinkIfNeeded() {
        guard let pending = pendingDeepLink else { return }
        pendingDeepLink = nil
        handle(deepLink: pending)
    }

    /// Resets to onboarding. Only called from Settings → "Sign out & start
    /// over" or from a debug menu — never as part of the normal flow.
    func resetForSignOut() {
        storage.hasCompletedOnboarding = false
        selectedTab = .today
        stage = .onboarding
    }

    /// Apply an inbound deep link. If the link targets a tab we honor it;
    /// otherwise we surface it via `pendingPresentation` for the active tab
    /// to consume. Returns `true` if the link was understood.
    @discardableResult
    func handle(deepLink: LuminaDeepLink) -> Bool {
        logger.debug("handling deep link: \(String(describing: deepLink))")
        guard stage == .mainTabs else {
            // Stash for after onboarding completes. (v2: queue persistence.)
            pendingDeepLink = deepLink
            return true
        }
        if let tab = deepLink.tab {
            selectedTab = tab
        }
        // Clear before assigning so a repeat tap of the same link still
        // registers as a change — consumers watch with `onChange`, and an
        // equal-to-stale write would never fire it.
        pendingPresentation = nil
        switch deepLink {
        case .today, .palmHistory:
            // Bare tab switches carry no payload and have no consumer, so
            // storing them would only leave a stale value behind.
            break
        default:
            pendingPresentation = deepLink
        }
        return true
    }
}

/// Persistence seam. `userDefaults` for production, `inMemory` for tests
/// so we never bleed state between cases. The reference-typed backing
/// store carries thread-safety responsibility (UserDefaults already is;
/// the in-memory variant uses a `DispatchQueue` lock).
struct AppRouterStorage: @unchecked Sendable {
    private enum Keys {
        static let onboardingComplete = "luminaOnboardingComplete"
        static let lastSelectedTab = "luminaLastSelectedTab"
    }

    static let userDefaults: AppRouterStorage = .init(backing: UserDefaultsBacking())

    private let backing: any AppRouterStorageBacking

    var hasCompletedOnboarding: Bool {
        get { backing.bool(for: Keys.onboardingComplete) }
        nonmutating set { backing.set(bool: newValue, for: Keys.onboardingComplete) }
    }

    var lastSelectedTab: LuminaTab {
        get {
            backing.string(for: Keys.lastSelectedTab)
                .flatMap(LuminaTab.init(rawValue:)) ?? .today
        }
        nonmutating set { backing.set(string: newValue.rawValue, for: Keys.lastSelectedTab) }
    }

    static func inMemory() -> AppRouterStorage {
        .init(backing: InMemoryBacking())
    }
}

private protocol AppRouterStorageBacking: Sendable {
    func bool(for key: String) -> Bool
    func set(bool value: Bool, for key: String)
    func string(for key: String) -> String?
    func set(string value: String, for key: String)
}

private struct UserDefaultsBacking: AppRouterStorageBacking {
    func bool(for key: String) -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }
    func set(bool value: Bool, for key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
    func string(for key: String) -> String? {
        UserDefaults.standard.string(forKey: key)
    }
    func set(string value: String, for key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}

private final class InMemoryBacking: AppRouterStorageBacking, @unchecked Sendable {
    private var bools: [String: Bool] = [:]
    private var strings: [String: String] = [:]
    private let queue = DispatchQueue(label: "app.lumina.AppRouterStorage.memory")

    func bool(for key: String) -> Bool {
        queue.sync { bools[key] ?? false }
    }
    func set(bool value: Bool, for key: String) {
        queue.sync { bools[key] = value }
    }
    func string(for key: String) -> String? {
        queue.sync { strings[key] }
    }
    func set(string value: String, for key: String) {
        queue.sync { strings[key] = value }
    }
}
