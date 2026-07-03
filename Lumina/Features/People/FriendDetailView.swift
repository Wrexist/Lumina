import SwiftData
import SwiftUI

/// Friend detail — compatibility headline, birth-info card, "remove
/// friend" with the standard `LuminaConfirmationDialog`.
struct FriendDetailView: View {
    let friend: Friend

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var confirmingRemove = false
    /// `nil` until a real score exists — we never render a fabricated number.
    @State private var score: Int?
    @ScaledMetric private var scoreSize: CGFloat = 56
    @State private var ephemeris = EphemerisService()
    @State private var synastry: SynastryLoad = .idle

    private enum SynastryLoad {
        case idle
        case loading
        case loaded([SynastryAspect])
        case missingBirthData
        case failed(LuminaError)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                header
                scoreCard
                shareSection
                birthInfoCard
                synastrySection
                CompositeCard(friend: friend)
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle(friend.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { trailingToolbar }
        .task {
            loadScore()
            await loadSynastry()
        }
        .luminaConfirmation(
            "Remove \(friend.name)?",
            message: "This deletes them from your People tab. You can add them again any time.",
            confirmTitle: "Remove",
            isPresented: $confirmingRemove,
            onConfirm: handleRemove
        )
    }

    // MARK: - View building blocks

    private var header: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
            Text("REFLECTION ON")
                .font(LuminaTypography.mono)
                .tracking(1.4)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            Text(friend.name)
                .font(LuminaTypography.display)
        }
    }

    private var scoreCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                if let score {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(score)")
                            .font(.system(size: scoreSize, weight: .light, design: .serif))
                            .foregroundStyle(LuminaColors.celestialBlue)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        Text("/100")
                            .font(LuminaTypography.bodyLight)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                        Spacer()
                        LuminaBadge(title: CompatibilityScorer.Label(score: score).displayName, tone: .neutral)
                    }
                }
                if let userBirth = UserBirthDataStore.userDefaults.load() {
                    Text(CompatibilityScorer.summary(
                        for: userBirth.birthDate, calendar: BirthMoment.calendar(userBirth.timeZoneIdentifier),
                        friend.birthDate, calendar: BirthMoment.calendar(friend.birthTimeZoneIdentifier)
                    ))
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                } else {
                    Text("Add your birth info in Settings to score this match.")
                        .font(LuminaTypography.caption)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                }
            }
        }
    }

    private var birthInfoCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                row("Birth date", value: dateString(friend.birthDate))
                row("Birth time", value: friend.birthTime.map(timeString) ?? "Unknown")
                row("Birth place", value: friend.birthPlaceName ?? "Unknown")
                row("Source", value: friend.source.rawValue.capitalized)
            }
        }
    }

    @ViewBuilder
    private var shareSection: some View {
        if case .loaded(let aspects) = synastry, !aspects.isEmpty, let score {
            CompatibilityShareButton(
                friendName: friend.name,
                score: score,
                headline: SynastrySummary.headline(for: aspects)
            )
        }
    }

    private var synastrySection: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("Between your charts")
                    .font(LuminaTypography.heading)
                synastryBody
            }
        }
    }

    @ViewBuilder
    private var synastryBody: some View {
        switch synastry {
        case .idle, .loading:
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                LuminaSkeleton(shape: .line(height: 16))
                LuminaSkeleton(shape: .line(width: 220, height: 14))
                LuminaSkeleton(shape: .line(width: 260, height: 14))
            }
        case .loaded(let aspects) where aspects.isEmpty:
            Text("No major aspects between your charts — an easy, low-friction connection.")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
        case .loaded(let aspects):
            Text(SynastrySummary.headline(for: aspects))
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack)
            Text("The real contacts behind it:")
                .font(LuminaTypography.caption)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            ForEach(Array(aspects.prefix(6))) { aspect in
                HStack(alignment: .top, spacing: LuminaSpacing.sm) {
                    Text("•").font(LuminaTypography.body)
                    Text(SynastryPhrasing.sentence(for: aspect)).font(LuminaTypography.body)
                }
            }
        case .missingBirthData:
            Text("Add your birth info in Settings to see the aspects between your charts.")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
        case .failed:
            synastryFailed
        }
    }

    /// Honest fetch failure with a retry — the user's birth data is present, so
    /// a network error must not send them to Settings to re-enter it.
    private var synastryFailed: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
            Text("Couldn't reach the sky just now")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            LuminaButton(title: "Retry", variant: .ghost, systemImage: "arrow.clockwise") {
                Task { await loadSynastry() }
            }
        }
    }

    @ToolbarContentBuilder
    private var trailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Remove", systemImage: "person.fill.xmark", role: .destructive) {
                    confirmingRemove = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("Friend options")
        }
    }

    // MARK: - Methods

    /// Resolves the displayed score outside `body` (mutating the model and
    /// saving during view evaluation triggers "modifying state during view
    /// update"). Uses the cached score when present, otherwise computes once.
    private func loadScore() {
        if let cached = friend.compatibilityScore {
            score = cached
            return
        }
        guard let userBirth = UserBirthDataStore.userDefaults.load() else { return }
        let computed = CompatibilityScorer.score(
            userBirth.birthDate, calendar: BirthMoment.calendar(userBirth.timeZoneIdentifier),
            friend.birthDate, calendar: BirthMoment.calendar(friend.birthTimeZoneIdentifier)
        )
        friend.compatibilityScore = computed
        modelContext.saveOrLog(category: "People")
        score = computed
    }

    /// Fetches the real chart-to-chart aspects from the backend. Best-effort:
    /// a missing user chart or a network failure shows an honest empty/locked
    /// state rather than fabricating contacts. Geocentric longitudes don't
    /// need birth place, so a friend with only a date still works.
    private func loadSynastry() async {
        guard let userBirth = UserBirthDataStore.userDefaults.load() else {
            synastry = .missingBirthData
            return
        }
        let mine = SynastryPerson(
            birthDate: userBirth.birthDate,
            birthTime: userBirth.birthTime,
            timeZoneIdentifier: userBirth.timeZoneIdentifier
        )
        let theirs = SynastryPerson(
            birthDate: friend.birthDate,
            birthTime: friend.birthTime,
            timeZoneIdentifier: friend.birthTimeZoneIdentifier
        )
        synastry = .loading
        do {
            let result = try await ephemeris.synastry(personA: mine, personB: theirs)
            applyLoadedAspects(result.aspects)
        } catch {
            #if DEBUG
            applyLoadedAspects(Self.sampleSynastry)
            #else
            // Birth data is present; a fetch failure is a network problem —
            // offer a retry rather than the missing-data copy.
            synastry = .failed(LuminaError.from(error))
            #endif
        }
    }

    /// Shows the real aspects and upgrades the displayed score from the
    /// Sun-sign heuristic to the synastry-weighted one, caching it on the
    /// friend so the People list reflects it next launch too.
    private func applyLoadedAspects(_ aspects: [SynastryAspect]) {
        synastry = .loaded(aspects)
        guard !aspects.isEmpty else { return }
        let synastryScore = CompatibilityScorer.score(fromSynastry: aspects)
        score = synastryScore
        friend.compatibilityScore = synastryScore
        modelContext.saveOrLog(category: "People")
    }

    #if DEBUG
    /// Dev-only stand-in so previews and no-backend builds show the section.
    private static let sampleSynastry: [SynastryAspect] = [
        SynastryAspect(planetA: "Venus", planetB: "Mars", type: .conjunction, exactAngle: 0, orb: 1.1),
        SynastryAspect(planetA: "Sun", planetB: "Moon", type: .trine, exactAngle: 120, orb: 1.6),
        SynastryAspect(planetA: "Moon", planetB: "Venus", type: .sextile, exactAngle: 60, orb: 2.0),
        SynastryAspect(planetA: "Mars", planetB: "Saturn", type: .square, exactAngle: 90, orb: 2.4),
    ]
    #endif

    private func handleRemove() {
        modelContext.delete(friend)
        modelContext.saveOrLog(category: "People")
        dismiss()
    }

    private func row(_ key: String, value: String) -> some View {
        HStack {
            Text(key.uppercased())
                .font(LuminaTypography.mono)
                .tracking(1.2)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            Spacer()
            Text(value).font(LuminaTypography.body)
        }
    }
}

// MARK: - Birth-info formatting

extension FriendDetailView {
    // Birth date/time render in the friend's birth-place zone (when known)
    // so the day and wall-clock time never shift on the viewer's device.
    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeZone = BirthMoment.calendar(friend.birthTimeZoneIdentifier).timeZone
        return formatter.string(from: date)
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = BirthMoment.calendar(friend.birthTimeZoneIdentifier).timeZone
        return formatter.string(from: date)
    }
}
