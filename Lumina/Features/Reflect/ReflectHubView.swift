import SwiftData
import SwiftUI

/// Phase-9 Reflect tab. Shows today's prompt, the entry editor (creating
/// today's entry on first tap), recent entries, and a "See history" link
/// into the calendar grid. Honors `AppPreferences.lockReflectWithFaceID`
/// — gates the whole tab behind `AppLock` until the user authenticates
/// for the session.
///
/// Free tier: first 3 entries free; entry #4 surfaces a soft Plus banner
/// backed by the real `IAPManager` purchase flow (see `Core/IAP/`).
struct ReflectHubView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @State private var preferences = AppPreferences.shared
    @State private var lock = AppLock.shared
    @State private var unlockError: LuminaError?
    @State private var unlocking = false
    @State private var openedEntry: JournalEntry?
    @State private var transits: [TransitReading] = []
    @State private var pendingDelete: JournalEntry?
    @State private var premium = PremiumStatus.shared
    @State private var usingSofterPrompt = false
    @AppStorage("luminaReflectPlusBannerDismissed") private var plusBannerDismissed = false
    @ScaledMetric private var lockIconSize: CGFloat = 56
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    /// Effective Reduce Motion — the OS setting or the in-app override.
    private var reduceMotion: Bool {
        LuminaMotion.isReduced(system: systemReduceMotion, appOverride: preferences.reduceMotionOverride)
    }

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
                history
                premiumBanner
            }
            .padding(LuminaSpacing.lg)
        }
        .navigationDestination(item: $openedEntry) { entry in
            JournalEntryView(entry: entry)
        }
        .task { await loadTransits() }
        .overlay(alignment: .bottom) { undoBar }
        .animation(reduceMotion ? nil : .smooth, value: pendingDelete?.id)
        .task(id: pendingDelete?.id) { await autoCommitPendingDelete() }
        .onAppear(perform: backfillReflectionMoments)
        .onDisappear(perform: commitPendingDelete)
    }

    @ViewBuilder
    private var undoBar: some View {
        if pendingDelete != nil {
            LuminaSnackbarView(message: "Entry removed", actionTitle: "Undo", onAction: cancelPendingDelete)
                .transition(reduceMotion ? .identity : .move(edge: .bottom).combined(with: .opacity))
        }
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
                // Only before today's entry exists — once created, the
                // entry's prompt is frozen and the card mirrors it.
                if todayEntry == nil {
                    LuminaButton(
                        title: usingSofterPrompt ? "Back to today's prompt" : "Try a softer prompt",
                        variant: .ghost
                    ) {
                        usingSofterPrompt.toggle()
                    }
                }
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
        if writtenEntryCount() >= 3 && !premium.isPremium && !plusBannerDismissed {
            LuminaCard {
                VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                    HStack {
                        LuminaBadge(title: "Plus", tone: .premium)
                        Text("Pattern detection at 30 entries")
                            .font(LuminaTypography.body)
                        Spacer()
                        Button {
                            plusBannerDismissed = true
                        } label: {
                            Image(systemName: "xmark")
                                .font(LuminaTypography.caption)
                                .foregroundStyle(LuminaColors.inkBlack.opacity(0.5))
                        }
                        .accessibilityLabel("Dismiss Plus banner")
                    }
                    Text("Once you've reflected for a month, Lumina Plus surfaces the emotional patterns connecting your entries. Free includes everything else.")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                }
            }
        }
    }

    /// Recent history excludes blank (`wordCount == 0`) entries — merely
    /// opening a day inserts one, and a page with no writing isn't history.
    /// Blank entries are kept in the store (never deleted), just not shown.
    private var recentWrittenEntries: [JournalEntry] {
        entries.filter { $0.wordCount > 0 && $0.id != pendingDelete?.id }
    }

    @ViewBuilder
    private var history: some View {
        if recentWrittenEntries.isEmpty {
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
                ForEach(Array(recentWrittenEntries.prefix(5))) { entry in
                    NavigationLink {
                        JournalEntryDetailView(entry: entry)
                    } label: {
                        entryRow(entry)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            softDelete(entry)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var todayEntry: JournalEntry? {
        let calendar = Calendar.current
        // Exclude the pending soft-delete — otherwise the CTA would push the
        // editor with an entry that `commitPendingDelete` removes out from
        // under it.
        return entries.first { calendar.isDateInToday($0.date) && $0.id != pendingDelete?.id }
    }

    /// The prompt shown on the card. Once today's entry exists, it shows the
    /// entry's frozen prompt so the card and the entry never disagree; before
    /// that, it's the live transit-tied prompt (falling back to the date pool
    /// until transits load).
    private var todaysPrompt: String {
        if let existing = todayEntry {
            return existing.prompt
        }
        if usingSofterPrompt {
            return JournalPromptGenerator.shared.softerPrompt(for: .now)
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
            transits = try await ChartCache.shared.transits(for: birth).transits
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
                Text("^[\(entry.wordCount) word](inflect: true)")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
        }
    }

    private func createTodayEntry() -> JournalEntry {
        let date = Date.now
        let prompt: String
        let key: String
        if usingSofterPrompt {
            // The softer prompt isn't transit-tied, so it keeps the plain
            // date key — the pattern detector shouldn't group it under a
            // transit it never references.
            prompt = JournalPromptGenerator.shared.softerPrompt(for: date)
            key = JournalPromptGenerator.shared.transitKey(for: date)
        } else {
            prompt = JournalPromptGenerator.shared.prompt(forTransits: transits, on: date)
            key = JournalPromptGenerator.shared.transitKey(forTransits: transits, on: date)
        }
        let entry = JournalEntry(date: date, prompt: prompt, transitKey: key)
        modelContext.insert(entry)
        modelContext.saveOrLog(category: "Reflect")
        recordReflectionMoments()
        return entry
    }
}

// MARK: - Soft delete

extension ReflectHubView {
    private func formattedDate(_ date: Date) -> String {
        let weekday = date.formatted(.dateTime.weekday(.wide))
        let monthDay = date.formatted(.dateTime.month(.abbreviated).day())
        return "\(weekday) · \(monthDay)".uppercased()
    }

    /// Soft-delete with an undo window; commits any prior pending delete first.
    func softDelete(_ entry: JournalEntry) {
        Haptics.warning.play()
        commitPendingDelete()
        pendingDelete = entry
    }

    func cancelPendingDelete() {
        Haptics.light.play()
        pendingDelete = nil
    }

    /// Waits out the undo window, then finalizes — cancelled when `pendingDelete`
    /// changes (undo, or a newer deletion supersedes it).
    func autoCommitPendingDelete() async {
        guard pendingDelete != nil else { return }
        try? await Task.sleep(for: .seconds(4))
        guard !Task.isCancelled else { return }
        commitPendingDelete()
    }

    func commitPendingDelete() {
        guard let entry = pendingDelete else { return }
        modelContext.delete(entry)
        modelContext.saveOrLog(category: "Reflect")
        pendingDelete = nil
    }
}

// MARK: - Moments

extension ReflectHubView {
    /// Marks reflection Moments after a new entry is created. Thresholds
    /// count only entries with real writing (`wordCount > 0`) — a blank
    /// entry the user opened but never wrote in earns nothing. Never
    /// consecutive days (brand: celebrate what happened; no streaks). The
    /// fetch count is authoritative because `@Query` may not refresh
    /// mid-action.
    private func recordReflectionMoments() {
        if MomentsStore.shared.recordReflection(totalCount: writtenEntryCount()) {
            Haptics.success.play()
        }
    }

    /// One-time silent reconcile on hub appearance: a user who upgrades (or
    /// returns after finally writing in a blank entry) with existing pages
    /// earns the reflection Moments they've already lived — no haptic, since
    /// this is backfill, not a fresh celebration.
    private func backfillReflectionMoments() {
        MomentsStore.shared.recordReflection(totalCount: writtenEntryCount())
    }

    /// Count of entries that actually contain writing. `wordCount` is a
    /// stored column, so the `#Predicate` count runs in the store; the array
    /// filter is only a fallback for a thrown fetch.
    private func writtenEntryCount() -> Int {
        let descriptor = FetchDescriptor<JournalEntry>(predicate: #Predicate { $0.wordCount > 0 })
        return (try? modelContext.fetchCount(descriptor)) ?? entries.filter { $0.wordCount > 0 }.count
    }
}

#Preview {
    NavigationStack {
        ReflectHubView()
    }
    .modelContainer(for: JournalEntry.self, inMemory: true)
}
