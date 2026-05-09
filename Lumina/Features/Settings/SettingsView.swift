import SwiftUI

/// Phase-12 settings shell. Ships now (rather than later in the roadmap)
/// because the nav-bar gear icon was a dead end without it — and the
/// clarity charter forbids dead ends.
///
/// Most rows are still placeholders that surface their future destination
/// via `LuminaBadge(title: "Soon", tone: .neutral)`. The real Settings
/// screens (manage subscription, edit birth info, privacy dashboard,
/// export data, delete account, help & FAQ) ship per Phase 12 of
/// `ROADMAP.md`.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var lockReflectWithFaceID = false
    @State private var reduceMotionOverride = false

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
        }
    }

    // MARK: - Sections

    private var accountSection: some View {
        Section("Account") {
            SettingsRow(title: "Manage subscription", trailing: .badge("Soon"))
            SettingsRow(title: "Restore purchases", trailing: .badge("Soon"))
            SettingsRow(title: "Sign in with Apple", trailing: .badge("Soon"))
        }
    }

    private var yourInfoSection: some View {
        Section("Your info") {
            SettingsRow(title: "Birth date", trailing: .badge("Soon"))
            SettingsRow(title: "Birth time", trailing: .badge("Soon"))
            SettingsRow(title: "Birth place", trailing: .badge("Soon"))
        }
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            SettingsRow(title: "House system", trailing: .text("Placidus"))
            NavigationLink {
                NotificationSettingsView()
            } label: {
                SettingsRow(title: "Notifications", trailing: nil)
            }
            Toggle(isOn: $lockReflectWithFaceID) {
                Text("Lock Reflect with Face ID").font(LuminaTypography.body)
            }
            Toggle(isOn: $reduceMotionOverride) {
                Text("Reduce motion").font(LuminaTypography.body)
            }
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            SettingsRow(title: "Privacy dashboard", trailing: .badge("Soon"))
            SettingsRow(title: "Export my data", trailing: .badge("Soon"))
            SettingsRow(title: "Delete my account", trailing: .badge("Soon"))
        }
    }

    private var aboutSection: some View {
        Section("About") {
            SettingsRow(title: "Help & FAQ", trailing: .badge("Soon"))
            SettingsRow(title: "Send feedback", trailing: .badge("Soon"))
            SettingsRow(title: "Terms of service", trailing: .badge("Soon"))
            SettingsRow(title: "Privacy policy", trailing: .badge("Soon"))
            SettingsRow(title: "Open-source acknowledgements", trailing: .badge("Soon"))
            HStack {
                Text("Version").font(LuminaTypography.body)
                Spacer()
                Text(versionString)
                    .font(LuminaTypography.mono)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            }
        }
    }

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "0.0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "\(short) (\(build))"
    }
}

private struct SettingsRow: View {
    enum Trailing {
        case badge(String)
        case text(String)
    }

    let title: String
    var trailing: Trailing?

    var body: some View {
        HStack {
            Text(title).font(LuminaTypography.body)
            Spacer()
            switch trailing {
            case .badge(let value):
                LuminaBadge(title: value, tone: .neutral)
            case .text(let value):
                Text(value)
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            case nil:
                EmptyView()
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.3))
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SettingsView()
}
