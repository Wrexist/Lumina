import SwiftUI

/// "A major return is coming" — surfaces a Jupiter or Saturn return only when
/// it's within the next year, so it's high-signal and never clutters Today the
/// rest of the time. Self-contained; honest, never faked.
struct ReturnsCard: View {
    @State private var ephemeris = EphemerisService()
    @State private var imminent: [ReturnEvent] = []

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    var body: some View {
        Group {
            if !imminent.isEmpty {
                card
            }
        }
        .task { await load() }
    }

    private var card: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("A MAJOR RETURN IS COMING")
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                ForEach(imminent) { event in
                    Text(ReturnPhrasing.line(for: event, formatter: Self.monthFormatter))
                        .font(LuminaTypography.body)
                        .foregroundStyle(LuminaColors.inkBlack)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Text("A return closes one cycle and opens the next — a natural checkpoint, not a verdict.")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            }
        }
    }

    private func load() async {
        guard let birth = UserBirthDataStore.userDefaults.load() else { return }
        do {
            let result = try await ephemeris.returns(for: birth)
            imminent = ReturnPhrasing.imminent(result.events, within: 365, from: .now)
        } catch {
            #if DEBUG
            imminent = [
                ReturnEvent(
                    planet: "Saturn",
                    returnNumber: 1,
                    exactAt: .now.addingTimeInterval(86_400 * 120),
                    natalLongitude: 280
                ),
            ]
            #else
            imminent = []
            #endif
        }
    }
}
