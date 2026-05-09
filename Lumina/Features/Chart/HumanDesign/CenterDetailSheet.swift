import SwiftUI

/// Center-tap detail sheet. Shows which gates the personality side
/// activated for this center, plus the planet that activated each one.
struct CenterDetailSheet: View {
    let center: HumanDesignCenter
    let activation: HumanDesignActivation

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                    statusHeader
                    if !contributing.isEmpty {
                        gatesCard
                    } else {
                        openCard
                    }
                    Text(BodygraphView.designSideMissingNote)
                        .font(LuminaTypography.caption)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.55))
                }
                .padding(LuminaSpacing.lg)
            }
            .background(LuminaColors.parchment)
            .navigationTitle(center.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - View building blocks

    private var contributing: [HumanDesignActivation.GateActivation] {
        activation.personality
            .filter { center.gates.contains($0.gate) }
            .sorted { $0.gate < $1.gate }
    }

    private var statusHeader: some View {
        let isDefined = activation.definedCenters.contains(center)
        return HStack(spacing: LuminaSpacing.sm) {
            LuminaBadge(title: isDefined ? "Defined" : "Open", tone: isDefined ? .premium : .neutral)
            Text(isDefined
                ? "Consistent energy here — you can rely on it."
                : "Open energy here — you take in others' input.")
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
        }
    }

    private var gatesCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("Activated gates")
                    .font(LuminaTypography.heading)
                ForEach(contributing, id: \.self) { activation in
                    HStack {
                        Text("Gate \(activation.gate).\(activation.line)")
                            .font(LuminaTypography.body)
                        Spacer()
                        Text(activation.planet)
                            .font(LuminaTypography.mono)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                    }
                }
            }
        }
    }

    private var openCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("None of this center's gates are activated by your personality side")
                    .font(LuminaTypography.body)
                Text("That doesn't mean the energy is absent — open centers receive and amplify the energy of the people you're around.")
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
        }
    }
}
