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
        case unavailable
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
            Text("Reading the road ahead…")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
        case .loaded(let events) where events.isEmpty:
            Text("No major exact transits in the next month — a steady stretch.")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
        case .loaded(let events):
            ForEach(events) { event in
                eventRow(event)
            }
        case .unavailable:
            Text("Add your birth info in Settings to see your timing.")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
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
            state = .unavailable
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
            state = .unavailable
            #endif
        }
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
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
