import SwiftUI

/// "Your relationship as one chart" — the composite (midpoint) chart of the
/// viewer and a friend, surfaced as the relationship's own core placements and
/// tightest real aspect. Self-contained (loads its own backend result) so the
/// friend-detail screen stays small. Honest empty/locked states — never faked.
struct CompositeCard: View {
    let friend: Friend

    @State private var ephemeris = EphemerisService()
    @State private var state: Load = .idle
    @ScaledMetric private var glyphSize: CGFloat = 28

    private enum Load {
        case idle
        case loading
        case loaded(CompositeResult)
        case missingBirthData
        case failed(LuminaError)
    }

    var body: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("Your relationship as one chart")
                    .font(LuminaTypography.heading)
                content
            }
        }
        .task { await load() }
    }

    // MARK: - View building blocks

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle, .loading:
            loadingState
        case .loaded(let composite):
            loaded(composite)
        case .missingBirthData:
            Text("Add your birth info in Settings to see your composite chart.")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
        case .failed:
            failedState
        }
    }

    /// Skeletons that mirror the loaded layout (NAVIGATION.md §4) rather than
    /// a bare "Merging…" line.
    private var loadingState: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
            LuminaSkeleton(shape: .line(height: 16))
            LuminaSkeleton(shape: .block(height: 60))
        }
    }

    /// Honest fetch failure with a retry — never the missing-birth-data copy,
    /// since the user's data is present. Compact, inside the existing card.
    private var failedState: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
            Text("Couldn't reach the sky just now")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            LuminaButton(title: "Retry", variant: .ghost, systemImage: "arrow.clockwise") {
                Task { await load() }
            }
        }
    }

    @ViewBuilder
    private func loaded(_ composite: CompositeResult) -> some View {
        if let headline = CompositePhrasing.headline(for: composite) {
            Text(headline)
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack)
        }
        coreBand(CompositePhrasing.coreSigns(for: composite))
        if let aspect = CompositePhrasing.tightestAspect(for: composite) {
            Text("Strongest thread: \(aspect)")
                .font(LuminaTypography.caption)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
        }
    }

    private func coreBand(_ signs: [CompositePhrasing.CoreSign]) -> some View {
        HStack(spacing: LuminaSpacing.md) {
            ForEach(signs) { item in
                VStack(spacing: LuminaSpacing.xs) {
                    Text(item.planet.uppercased())
                        .font(LuminaTypography.mono)
                        .tracking(1.4)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                    Text(ChartGlyphs.signGlyph(item.sign))
                        .font(.system(size: glyphSize))
                        .foregroundStyle(LuminaColors.mutedGold)
                    Text(item.sign)
                        .font(LuminaTypography.caption)
                        .foregroundStyle(LuminaColors.inkBlack)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Methods

    /// Best-effort fetch of the merged chart. A missing user chart or a network
    /// failure shows an honest locked state rather than fabricating a reading.
    private func load() async {
        guard let userBirth = UserBirthDataStore.userDefaults.load() else {
            state = .missingBirthData
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
        state = .loading
        do {
            let result = try await ephemeris.composite(personA: mine, personB: theirs)
            state = .loaded(result)
        } catch {
            #if DEBUG
            state = .loaded(Self.sample)
            #else
            // Birth data is present; a fetch failure is a network problem, not
            // missing data — offer a retry rather than the Settings lie.
            state = .failed(LuminaError.from(error))
            #endif
        }
    }

    #if DEBUG
    /// Dev-only stand-in so previews and no-backend builds show the section.
    private static let sample = CompositeResult(
        calculatedAt: .now,
        planets: [
            NatalChart.PlanetPosition(planet: "Sun", longitude: 195, latitude: 0, isRetrograde: false),
            NatalChart.PlanetPosition(planet: "Moon", longitude: 65, latitude: 0, isRetrograde: false),
            NatalChart.PlanetPosition(planet: "Venus", longitude: 220, latitude: 0, isRetrograde: false),
        ],
        aspects: [
            NatalChart.Aspect(planet1: "Sun", planet2: "Venus", type: .sextile, exactAngle: 60, orb: 1.2),
        ]
    )
    #endif
}
