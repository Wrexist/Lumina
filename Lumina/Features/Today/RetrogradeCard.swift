import SwiftUI

/// "Retrogrades" — which bodies are currently in apparent backward motion and
/// when each turns direct. Global sky data, so it loads itself; it stays hidden
/// unless something is actually retrograde, keeping Today calm when the sky is
/// clear. Real ephemeris, never faked.
struct RetrogradeCard: View {
    @State private var ephemeris = EphemerisService()
    @State private var result: RetrogradesResult?

    private static let stationFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    var body: some View {
        Group {
            if let result, result.planets.contains(where: \.isRetrograde) {
                loaded(result)
            }
        }
        .task { await load() }
    }

    private func loaded(_ result: RetrogradesResult) -> some View {
        let retrograde = result.planets.filter(\.isRetrograde)
        return LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("RETROGRADES")
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                Text(RetrogradePhrasing.summary(for: result))
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(retrograde) { state in
                    if let line = RetrogradePhrasing.stationLine(for: state, formatter: Self.stationFormatter) {
                        HStack(alignment: .top, spacing: LuminaSpacing.sm) {
                            Text("•").font(LuminaTypography.caption)
                            Text(line)
                                .font(LuminaTypography.caption)
                                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                        }
                    }
                }
            }
        }
    }

    private func load() async {
        do {
            result = try await ephemeris.retrogrades()
        } catch {
            #if DEBUG
            result = Self.sample
            #else
            result = nil
            #endif
        }
    }

    #if DEBUG
    private static let sample = RetrogradesResult(
        calculatedAt: .now,
        at: .now,
        planets: [
            RetrogradeState(
                planet: "Mercury",
                isRetrograde: true,
                nextStationAt: .now.addingTimeInterval(86_400 * 9),
                nextStationDirection: .direct
            ),
            RetrogradeState(planet: "Venus", isRetrograde: false, nextStationAt: nil, nextStationDirection: nil),
        ]
    )
    #endif
}
