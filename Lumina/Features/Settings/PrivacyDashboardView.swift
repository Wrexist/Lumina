import SwiftData
import SwiftUI

/// "What we know about you, and what we don't." First-of-its-kind in
/// this category — see `ROADMAP.md` Phase 12 and `docs/NAVIGATION.md` §11.
///
/// All counts read directly from on-device SwiftData / UserDefaults.
/// No network call is made to render this screen.
struct PrivacyDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var journalEntries: [JournalEntry]
    @Query private var friends: [Friend]
    @State private var hasBirthData = false
    @State private var hasOnboardingState = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                hero
                onDeviceCard
                onServerCard
                notStoredCard
                actionsCard
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle("Privacy dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            hasBirthData = UserBirthDataStore.userDefaults.load() != nil
            hasOnboardingState = UserDefaults.standard.data(forKey: "luminaOnboardingSnapshot") != nil
        }
    }

    // MARK: - View building blocks

    private var hero: some View {
        Text("Lumina is honest about what it stores and where. This dashboard reflects exactly what's on your device and on our servers right now.")
            .font(LuminaTypography.body)
            .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
    }

    private var onDeviceCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                sectionHeader("On this device", systemImage: "iphone")
                row("Your birth chart", value: hasBirthData ? "Yes" : "Not set")
                row("Reflect entries", value: "\(journalEntries.count)")
                row("Friends", value: "\(friends.count)")
                row("Onboarding state", value: hasOnboardingState ? "Saved" : "Cleared")
            }
        }
    }

    private var onServerCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                sectionHeader("On our server", systemImage: "server.rack")
                row("Your account", value: "—")
                row("Active subscription status", value: "—")
                row("Push token", value: "—")
                Text("Account + subscription rows fill in once Sign in with Apple + RevenueCat are wired (Phases 12, 16).")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            }
        }
    }

    private var notStoredCard: some View {
        LuminaCard(surface: .glass) {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                sectionHeader("What's never stored", systemImage: "lock.shield")
                bullet("Your palm photos — discarded after on-device line extraction")
                bullet("Your Reflect entry text — never leaves this device")
                bullet("Your contacts — only birthdays you import are read, and they're stored locally")
                bullet("Your location — used at onboarding to find your birth place, then forgotten")
            }
        }
    }

    private var actionsCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                sectionHeader("Your data", systemImage: "tray.and.arrow.down")
                Text("Export to JSON and account deletion ship later in Phase 12. Until then, your local data lives only on this device — uninstalling the app removes everything.")
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                LuminaBadge(title: "Soon", tone: .neutral)
            }
        }
    }

    // MARK: - Methods

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack(spacing: LuminaSpacing.sm) {
            Image(systemName: systemImage)
                .foregroundStyle(LuminaColors.celestialBlue)
            Text(title).font(LuminaTypography.heading)
        }
    }

    private func row(_ key: String, value: String) -> some View {
        HStack {
            Text(key).font(LuminaTypography.body)
            Spacer()
            Text(value)
                .font(LuminaTypography.mono)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: LuminaSpacing.sm) {
            Text("•").font(LuminaTypography.body)
            Text(text).font(LuminaTypography.body)
        }
    }
}

#Preview {
    NavigationStack { PrivacyDashboardView() }
        .modelContainer(for: [JournalEntry.self, Friend.self], inMemory: true)
}
