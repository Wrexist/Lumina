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
        case unavailable
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
            Text("Merging your two charts…")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
        case .loaded(let composite):
            loaded(composite)
        case .unavailable:
            Text("Add your birth info in Settings to see your composite chart.")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
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
            state = .unavailable
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
            state = .unavailable
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
