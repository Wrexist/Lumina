import SwiftUI
import UIKit

/// Phase-12 settings shell. Ships now (rather than later in the roadmap)
/// because the nav-bar gear icon was a dead end without it — and the
/// clarity charter forbids dead ends.
///
/// Every visible row does something. The destinations that haven't been
/// built yet (data export, account deletion, legal documents) are collapsed
/// into section footnotes rather than inert "Soon" rows; they ship per
/// Phase 12 of `ROADMAP.md`.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var preferences = AppPreferences.shared
    @State private var restoreMessage: String?
    @State private var isRestoringPurchases = false
    @State private var authManager = AuthManager.shared
    @State private var signInPresented = false

    var body: some View {
        NavigationStack {
            List {
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
        }
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
        }
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            // Read-only info until house-system selection ships — styled
            // like the Version row (mono, dimmed) so it doesn't read as a
            // tappable destination.
            HStack {
                Text("House system").font(LuminaTypography.body)
                Spacer()
                Text("Placidus")
                    .font(LuminaTypography.mono)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            }
            .accessibilityElement(children: .combine)
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
            sectionFootnote("Data export and account deletion are coming before public launch.")
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
        } header: {
            Text("About")
        } footer: {
            sectionFootnote("Terms of service, privacy policy, and open-source acknowledgements "
                + "are coming before public launch.")
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
}
