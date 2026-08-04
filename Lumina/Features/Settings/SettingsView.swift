import OSLog
import SwiftData
import SwiftUI
import UIKit

/// Phase-12 settings shell. Ships now (rather than later in the roadmap)
/// because the nav-bar gear icon was a dead end without it — and the
/// clarity charter forbids dead ends.
///
/// Every visible row does something. Account deletion and the legal links
/// ship here; the one destination still pending (full data export) is
/// collapsed into a section footnote rather than an inert "Soon" row.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @State private var preferences = AppPreferences.shared
    @State private var restoreMessage: String?
    @State private var isRestoringPurchases = false
    @State private var authManager = AuthManager.shared
    @State private var premium = PremiumStatus.shared
    @State private var signInPresented = false
    @State private var deleteAccountConfirmPresented = false
    @State private var isDeletingAccount = false
    private let logger = Logger(subsystem: "app.lumina.ios", category: "AccountDeletion")

    var body: some View {
        NavigationStack {
            List {
                plusSection
                accountSection
                yourInfoSection
                preferencesSection
                privacySection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(LuminaColors.parchment)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay(alignment: .bottom) { restoreBanner }
            .animation(.smooth, value: restoreMessage)
            .sheet(isPresented: $signInPresented) {
                SignInView { _ in signInPresented = false }
            }
        }
    }

    // MARK: - Sections

    /// A persistent, always-reachable upgrade surface.
    ///
    /// The paywall used to be presented from exactly one place — a one-shot
    /// during onboarding gated on `hasSeenInitialOffer` — so a user who
    /// tapped "Continue free" once could never buy the subscription again.
    /// That is also the classic "we were unable to locate the in-app
    /// purchase" App Review rejection, because a reviewer who skips the
    /// onboarding offer has no way to reach it.
    private var plusSection: some View {
        Section("Lumina Plus") {
            if premium.isPremium {
                SettingsRow(title: "Status", trailing: .text("Active"))
                    .accessibilityLabel("Lumina Plus is active")
            } else {
                Button {
                    PaywallPresenter.shared.present()
                } label: {
                    SettingsRow(title: "Upgrade to Lumina Plus", trailing: nil)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var accountSection: some View {
        Section("Account") {
            Button(action: openManageSubscription) {
                SettingsRow(title: "Manage subscription", trailing: nil)
            }
            .buttonStyle(.plain)
            Button(action: restorePurchases) {
                SettingsRow(title: "Restore purchases", trailing: nil)
            }
            .buttonStyle(.plain)
            .disabled(isRestoringPurchases)
            signInRow
            deleteAccountRow
        }
    }

    /// Apple Guideline 5.1.1(v): a real in-app path to erase the account and
    /// all on-device data. Destructive-styled, gated behind a confirmation
    /// dialog, and available even when signed out (a local-only user still
    /// needs their on-device chart, journal, and friends wiped).
    private var deleteAccountRow: some View {
        Button(role: .destructive) {
            deleteAccountConfirmPresented = true
        } label: {
            HStack {
                Text("Delete account")
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.error)
                Spacer()
                if isDeletingAccount {
                    ProgressView()
                }
            }
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(.plain)
        .disabled(isDeletingAccount)
        .luminaConfirmation(
            "Delete your account?",
            message: "This permanently erases your birth chart, journal entries, saved friends, "
                + "and your Lumina account. This can't be undone.",
            confirmTitle: "Delete everything",
            isPresented: $deleteAccountConfirmPresented,
            onConfirm: performAccountDeletion
        )
    }

    @ViewBuilder
    private var signInRow: some View {
        if let session = authManager.session {
            Button(action: authManager.signOut) {
                SettingsRow(title: "Sign out", trailing: .text(session.displayName ?? session.email ?? "Signed in"))
            }
            .buttonStyle(.plain)
        } else {
            Button(action: presentSignIn) {
                SettingsRow(title: "Sign in with Apple", trailing: nil)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var restoreBanner: some View {
        if let restoreMessage {
            LuminaSnackbarView(message: restoreMessage, actionTitle: "Dismiss") {
                self.restoreMessage = nil
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var yourInfoSection: some View {
        Section("Your info") {
            NavigationLink {
                EditBirthInfoView()
            } label: {
                SettingsRow(title: "Birth date, time, and place", trailing: nil)
            }
            NavigationLink {
                MomentsView()
            } label: {
                SettingsRow(title: "Moments", trailing: nil)
            }
        }
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            // House-system selection lives in the Chart tab (Placidus /
            // Whole-sign / Sidereal). This used to be a static read-only
            // "Placidus" row, which contradicted that control and told users
            // their chart was Placidus even when it wasn't.
            Button {
                _ = router.handle(deepLink: .chart(planet: nil))
                dismiss()
            } label: {
                SettingsRow(title: "House system", trailing: .text("Choose in Chart"))
            }
            .buttonStyle(.plain)
            NavigationLink {
                NotificationSettingsView()
            } label: {
                SettingsRow(title: "Notifications", trailing: nil)
            }
            Toggle(isOn: $preferences.lockReflectWithFaceID) {
                Text("Lock Reflect with Face ID").font(LuminaTypography.body)
            }
            Toggle(isOn: $preferences.reduceMotionOverride) {
                Text("Reduce motion").font(LuminaTypography.body)
            }
        }
    }

    private var privacySection: some View {
        Section {
            NavigationLink {
                PrivacyDashboardView()
            } label: {
                SettingsRow(title: "Privacy dashboard", trailing: nil)
            }
        } header: {
            Text("Privacy")
        } footer: {
            sectionFootnote("Delete your account any time from the Account section above. "
                + "Full data export is coming before public launch.")
        }
    }

    private var aboutSection: some View {
        Section {
            NavigationLink {
                HelpView()
            } label: {
                SettingsRow(title: "Help & FAQ", trailing: nil)
            }
            HStack {
                Text("Version").font(LuminaTypography.body)
                Spacer()
                Text(versionString)
                    .font(LuminaTypography.mono)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            }
            sectionFootnote("On-device palm reading is in the works — we're getting fairness "
                + "across every skin tone right before we ship it. Lumina is for reflection "
                + "and entertainment, not medical, legal, or financial advice.")
        } header: {
            Text("About")
        } footer: {
            LuminaLegalLinks()
        }
    }

    /// Caption-style footnote for destinations that aren't built yet —
    /// one honest line instead of a stack of inert "Soon" rows.
    private func sectionFootnote(_ text: String) -> some View {
        Text(text)
            .font(LuminaTypography.caption)
            .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
    }

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "0.0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "\(short) (\(build))"
    }

    // MARK: - Actions

    private func presentSignIn() {
        signInPresented = true
    }

    private func openManageSubscription() {
        guard let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") else { return }
        UIApplication.shared.open(url)
    }

    private func restorePurchases() {
        guard !isRestoringPurchases else { return }
        isRestoringPurchases = true
        Task {
            defer { isRestoringPurchases = false }
            do {
                let isPremium = try await IAPManager.shared.restorePurchases()
                Haptics.success.play()
                restoreMessage = isPremium ? "Your Lumina Plus subscription is restored." : "No active subscription found."
            } catch {
                Haptics.failure.play()
                restoreMessage = "Couldn't restore purchases right now. Try again in a moment."
            }
        }
    }
}

extension SettingsView {
    /// Runs the full account teardown, then returns the user to onboarding.
    ///
    /// Ordering matters. This used to erase every model *before* tearing down
    /// the navigation, and `eraseLocalData()` keeps awaiting afterwards
    /// (`ChartCache.clear()`), so `MainTabsView` — and anything pushed inside
    /// it, e.g. a `FriendDetailView` reached via the toolbar gear — was still
    /// mounted and re-rendering against destroyed models. Swap the root out
    /// first, then erase.
    private func performAccountDeletion() {
        guard !isDeletingAccount else { return }
        isDeletingAccount = true
        Task {
            // `(any Error)?`, not `Error?` — the target builds with warnings
            // as errors, and a bare protocol-as-type is a Swift 6 diagnostic.
            var serverFailure: (any Error)?
            do {
                try await AuthManager.shared.deleteAccount()
            } catch {
                // Deletion of the server account genuinely failed. Still wipe
                // locally — the user asked for it — but don't claim success.
                serverFailure = error
            }

            // Unmount the tab UI before destroying the models it renders.
            router.resetForSignOut()
            dismiss()
            await eraseLocalData()
            isDeletingAccount = false

            if serverFailure != nil {
                restoreMessage = "Everything on this device was erased, but we couldn't reach the server to remove your account. Please try again once you're back online."
            }
        }
    }

    /// Wipes every on-device store so nothing of the deleted account survives:
    /// SwiftData (`JournalEntry` + `Friend`), birth data, the onboarding
    /// snapshot, the widget App-Group snapshot, progression state (Moments +
    /// chart discovery), tunable preferences, and the app-lock session; and
    /// cancels every scheduled notification derived from that data. Keychain
    /// is handled inside `deleteAccount()`.
    private func eraseLocalData() async {
        // Stop future notifications first — a repeating reflect reminder would
        // otherwise keep firing forever, and transit alerts carry the deleted
        // chart. (Setting the prefs off below does not itself cancel them.)
        ReflectReminderScheduler.shared.cancel()
        await TransitNotificationScheduler.shared.cancelAll()

        // Surface erasure failures rather than swallowing them — this is a
        // compliance-critical path (Apple 5.1.1(v)), so a partial failure must
        // be observable, not silently reported as success.
        do {
            try modelContext.delete(model: JournalEntry.self)
            try modelContext.delete(model: Friend.self)
            try modelContext.save()
        } catch {
            logger.error("local data erasure failed: \(error.localizedDescription, privacy: .public)")
        }
        UserBirthDataStore.userDefaults.clear()
        OnboardingStorage.userDefaults.clear()
        WidgetSharedStore.clear()
        MomentsStore.shared.clear()
        ChartDiscovery.shared.clear()
        // Drop the persisted natal chart + every cached ephemeris read so the
        // deleted account leaves nothing behind (Apple 5.1.1(v)).
        await ChartCache.shared.clear()
        resetPreferences()
        AppLock.shared.resetSessionUnlocks()
    }

    /// `AppPreferences` exposes no single reset, so restore each user-tunable
    /// flag to its default via its public setters.
    private func resetPreferences() {
        preferences.lockReflectWithFaceID = false
        preferences.reduceMotionOverride = false
        preferences.transitAlertsEnabled = false
        preferences.reflectReminderEnabled = false
    }
}

private struct SettingsRow: View {
    enum Trailing {
        case text(String)
    }

    let title: String
    var trailing: Trailing?

    var body: some View {
        HStack {
            Text(title).font(LuminaTypography.body)
            Spacer()
            switch trailing {
            case .text(let value):
                Text(value)
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            case nil:
                EmptyView()
            }
            // No manual chevron: NavigationLink rows get the system disclosure
            // indicator automatically, so plain rows correctly show none
            // rather than a misleading affordance.
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SettingsView()
        .environment(AppRouter(storage: .inMemory()))
        .modelContainer(for: [JournalEntry.self, Friend.self], inMemory: true)
}
