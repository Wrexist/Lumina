import SwiftUI

/// "What's coming" — the exact dates the user's upcoming transits perfect,
/// from the backend `/forecast`. The fast Moon is filtered out so the
/// meaningful slower-planet timing stands out. Pushed from the Today tab.
struct ForecastView: View {
    @State private var ephemeris = EphemerisService()
    @State private var state: Load = .idle

    private enum Load {
        case idle
        case loading
        case loaded([ForecastEvent])
        case missingBirthData
        case failed(LuminaError)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                Text("The exact dates your upcoming transits perfect — real timing from where the planets are actually headed.")
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                content
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle("What's coming")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle, .loading:
            loadingState
        case .loaded(let events) where events.isEmpty:
            Text("No major exact transits in the next month — a steady stretch.")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
        case .loaded(let events):
            ForEach(events) { event in
                eventRow(event)
            }
        case .missingBirthData:
            Text("Add your birth info in Settings to see your timing.")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
        case .failed:
            failedCard
        }
    }

    /// Fixed-height skeletons that mirror the event rows (NAVIGATION.md §4)
    /// instead of a bare "Reading…" line.
    private var loadingState: some View {
        VStack(spacing: LuminaSpacing.md) {
            LuminaSkeleton(shape: .block(height: 72))
            LuminaSkeleton(shape: .block(height: 72))
            LuminaSkeleton(shape: .block(height: 72))
        }
    }

    /// Honest transit-fetch failure with a retry — never the missing-birth-data
    /// copy, which would send users to re-enter data they already have. Mirrors
    /// Today's `transitsUnavailableCard`.
    private var failedCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("Couldn't reach the sky just now")
                    .font(LuminaTypography.heading)
                Text("Your timing is grounded in the real transits, and we couldn't fetch them just now.")
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                LuminaButton(title: "Retry", variant: .ghost, systemImage: "arrow.clockwise") {
                    Task { await load() }
                }
            }
        }
    }

    private func eventRow(_ event: ForecastEvent) -> some View {
        LuminaCard(padding: LuminaSpacing.md) {
            VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                Text(ForecastPhrasing.line(for: event))
                    .font(LuminaTypography.body)
                Text(Self.dateText(event.exactAt))
                    .font(LuminaTypography.mono)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.55))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func load() async {
        guard let birth = UserBirthDataStore.userDefaults.load() else {
            state = .missingBirthData
            return
        }
        state = .loading
        do {
            let result = try await ephemeris.forecast(for: birth)
            // Drop the fast Moon — it aspects everything daily and drowns out signal.
            state = .loaded(result.events.filter { $0.transiting != "Moon" })
        } catch {
            #if DEBUG
            state = .loaded(Self.sampleEvents)
            #else
            // Birth data is present (we loaded it above); a fetch failure is a
            // network problem, not missing data — offer a retry, don't lie.
            state = .failed(LuminaError.from(error))
            #endif
        }
    }

    /// Locale-aware weekday + month/day (e.g. "Thu, Jul 2" in en-US, reordered
    /// and localized elsewhere) — never a hardcoded `DateFormatter` template.
    private static func dateText(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    #if DEBUG
    static let sampleEvents: [ForecastEvent] = [
        ForecastEvent(transiting: "Mars", natal: "Venus", type: .trine, exactAngle: 120, exactAt: Date().addingTimeInterval(2 * 86_400)),
        ForecastEvent(transiting: "Mercury", natal: "Saturn", type: .square, exactAngle: 90, exactAt: Date().addingTimeInterval(6 * 86_400)),
        ForecastEvent(transiting: "Saturn", natal: "Sun", type: .trine, exactAngle: 120, exactAt: Date().addingTimeInterval(13 * 86_400)),
        ForecastEvent(transiting: "Jupiter", natal: "Moon", type: .sextile, exactAngle: 60, exactAt: Date().addingTimeInterval(21 * 86_400)),
    ]
    #endif
}
