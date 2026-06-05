import SwiftData
import SwiftUI

/// Phase-9 Reflect tab. Shows today's prompt, the entry editor (creating
/// today's entry on first tap), recent entries, and a "See history" link
/// into the calendar grid. Honors `AppPreferences.lockReflectWithFaceID`
/// — gates the whole tab behind `AppLock` until the user authenticates
/// for the session.
///
/// Free tier: first 3 entries free; entry #4 surfaces a soft Plus banner
/// (the actual purchase wires through RevenueCat in Phase 16).
struct ReflectHubView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @State private var preferences = AppPreferences.shared
    @State private var lock = AppLock.shared
    @State private var unlockError: LuminaError?
    @State private var unlocking = false
    @State private var openedEntry: JournalEntry?
    @State private var ephemeris = EphemerisService()
    @State private var transits: [TransitReading] = []
    @ScaledMetric private var lockIconSize: CGFloat = 56

    var body: some View {
        Group {
            if preferences.lockReflectWithFaceID && !lock.unlocked.contains(.reflectTab) {
                lockedScreen
            } else {
                unlockedContent
            }
        }
        .background(LuminaColors.parchment)
        .navigationTitle("Reflect")
    }

    // MARK: - View building blocks

    private var lockedScreen: some View {
        VStack(spacing: LuminaSpacing.lg) {
            Spacer()
            Image(systemName: "lock.shield")
                .font(.system(size: lockIconSize))
                .foregroundStyle(LuminaColors.celestialBlue)
            Text("Reflect is locked")
                .font(LuminaTypography.heading)
            Text("Use Face ID or your passcode to open your reflections.")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, LuminaSpacing.lg)
            if let unlockError {
                Text(unlockError.userBody)
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LuminaSpacing.lg)
            }
            Spacer()
            LuminaButton(title: unlocking ? "Authenticating…" : "Unlock", variant: .primary, isLoading: unlocking) {
                Task { await unlock() }
            }
            .padding(LuminaSpacing.lg)
        }
    }

    private var unlockedContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                todaysPromptCard
                primaryCTA
                premiumBanner
                history
            }
            .padding(LuminaSpacing.lg)
        }
        .navigationDestination(item: $openedEntry) { entry in
            JournalEntryView(entry: entry)
        }
        .task { await loadTransits() }
    }

    private var todaysPromptCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("TODAY'S PROMPT")
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                Text(todaysPrompt)
                    .font(LuminaTypography.heading)
                Text("Auto-saved on this device only.")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            }
        }
    }

    private var primaryCTA: some View {
        let title = todayEntry == nil ? "Write today's reflection" : "Continue today's reflection"
        // Value-based navigation: the entry is created in the tap handler, NOT
        // in a NavigationLink destination builder (which SwiftUI evaluates
        // eagerly during `body`, inserting blank entries on mere tab open).
        return LuminaButton(title: title, variant: .primary, systemImage: "pencil", action: openTodayEntry)
    }

    @ViewBuilder
    private var premiumBanner: some View {
        if entries.count >= 3 {
            LuminaCard {
                VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                    HStack {
                        LuminaBadge(title: "Plus", tone: .premium)
                        Text("Pattern detection at 30 entries")
                            .font(LuminaTypography.body)
                    }
                    Text("Once you've reflected for a month, Lumina Plus surfaces the emotional patterns connecting your entries. Free includes everything else.")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                }
            }
        }
    }

    @ViewBuilder
    private var history: some View {
        if entries.isEmpty {
            // No empty-state CTA here — the primary CTA above already
            // serves the empty state. Hide the history section to avoid
            // a "no entries" dead-end.
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                HStack {
                    Text("RECENT")
                        .font(LuminaTypography.mono)
                        .tracking(1.4)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                    Spacer()
                    NavigationLink("See history") {
                        JournalCalendarView()
                    }
                    .font(LuminaTypography.caption)
                }
                ForEach(entries.prefix(5)) { entry in
                    NavigationLink {
                        JournalEntryDetailView(entry: entry)
                    } label: {
                        entryRow(entry)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var todayEntry: JournalEntry? {
        let calendar = Calendar.current
        return entries.first { calendar.isDateInToday($0.date) }
    }

    /// The prompt shown on the card. Once today's entry exists, it shows the
    /// entry's frozen prompt so the card and the entry never disagree; before
    /// that, it's the live transit-tied prompt (falling back to the date pool
    /// until transits load).
    private var todaysPrompt: String {
        if let existing = todayEntry {
            return existing.prompt
        }
        return JournalPromptGenerator.shared.prompt(forTransits: transits, on: .now)
    }

    // MARK: - Methods

    private func openTodayEntry() {
        openedEntry = todayEntry ?? createTodayEntry()
    }

    /// Best-effort load of today's real transits so the prompt reflects the
    /// actual sky. On any failure (no birth data, offline) `transits` stays
    /// empty and the prompt falls back to the date-keyed pool — no error shown.
    private func loadTransits() async {
        guard transits.isEmpty, let birth = UserBirthDataStore.userDefaults.load() else { return }
        do {
            transits = try await ephemeris.transits(for: birth).transits
        } catch {
            transits = []
        }
    }

    private func unlock() async {
        guard !unlocking else { return }
        unlocking = true
        defer { unlocking = false }
        do {
            try await lock.unlock(.reflectTab, prompt: "Open your reflections.")
            unlockError = nil
        } catch let error as AppLock.LockError {
            switch error {
            case .userCancelled:
                unlockError = nil
            case .notEnrolled, .unavailable:
                unlockError = .permissionDenied(kind: .faceID)
            case .failed(let reason):
                unlockError = .unknown(underlyingMessage: reason)
            }
        } catch {
            unlockError = LuminaError.from(error)
        }
    }

    private func entryRow(_ entry: JournalEntry) -> some View {
        LuminaCard(padding: LuminaSpacing.md) {
            VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                Text(formattedDate(entry.date))
                    .font(LuminaTypography.mono)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                Text(entry.prompt)
                    .font(LuminaTypography.body)
                    .lineLimit(2)
                Text("\(entry.wordCount) words")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.5))
            }
        }
    }

    private func createTodayEntry() -> JournalEntry {
        let date = Date.now
        let prompt = JournalPromptGenerator.shared.prompt(forTransits: transits, on: date)
        let key = JournalPromptGenerator.shared.transitKey(forTransits: transits, on: date)
        let entry = JournalEntry(date: date, prompt: prompt, transitKey: key)
        modelContext.insert(entry)
        modelContext.saveOrLog(category: "Reflect")
        return entry
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE · MMM d"
        return formatter.string(from: date).uppercased()
    }
}

#Preview {
    NavigationStack {
        ReflectHubView()
    }
    .modelContainer(for: JournalEntry.self, inMemory: true)
}
