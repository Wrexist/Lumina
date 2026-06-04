import SwiftData
import SwiftUI

/// Friend detail — compatibility headline, birth-info card, "remove
/// friend" with the standard `LuminaConfirmationDialog`.
struct FriendDetailView: View {
    let friend: Friend

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var confirmingRemove = false
    @State private var score = 50
    @ScaledMetric private var scoreSize: CGFloat = 56
    @State private var ephemeris = EphemerisService()
    @State private var synastry: SynastryLoad = .idle

    private enum SynastryLoad {
        case idle
        case loading
        case loaded([SynastryAspect])
        case unavailable
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                header
                scoreCard
                birthInfoCard
                synastrySection
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
        let label = CompatibilityScorer.Label(score: score)
        return LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
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
                    LuminaBadge(title: label.displayName, tone: .neutral)
                }
                if let userBirth = UserBirthDataStore.userDefaults.load() {
                    Text(CompatibilityScorer.summary(for: userBirth.birthDate, friend.birthDate))
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
            Text("Reading the aspects between you…")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
        case .loaded(let aspects) where aspects.isEmpty:
            Text("No major aspects between your charts — an easy, low-friction connection.")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
        case .loaded(let aspects):
            Text("The real chart-to-chart contacts between you.")
                .font(LuminaTypography.bodyLight)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            ForEach(Array(aspects.prefix(6))) { aspect in
                HStack(alignment: .top, spacing: LuminaSpacing.sm) {
                    Text("•").font(LuminaTypography.body)
                    Text(SynastryPhrasing.sentence(for: aspect)).font(LuminaTypography.body)
                }
            }
        case .unavailable:
            Text("Add your birth info in Settings to see the aspects between your charts.")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
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
        let computed = CompatibilityScorer.score(userBirth.birthDate, friend.birthDate)
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
            synastry = .unavailable
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
            synastry = .loaded(result.aspects)
        } catch {
            #if DEBUG
            synastry = .loaded(Self.sampleSynastry)
            #else
            synastry = .unavailable
            #endif
        }
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

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
