import SwiftUI

/// Pill-style segmented control with mono uppercase labels. Used by the
/// house-system picker on Chart, the Western/Vedic chart-mode toggle, and
/// the time-window picker on Compatibility.
struct LuminaSegmentedControl<Value: Hashable>: View {
    let options: [(value: Value, label: String)]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                Button {
                    selection = option.value
                } label: {
                    Text(option.label.uppercased())
                        .font(LuminaTypography.mono)
                        .tracking(1.4)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .foregroundStyle(
                            option.value == selection
                                ? LuminaColors.parchment
                                : LuminaColors.inkBlack
                        )
                        .background(
                            option.value == selection
                                ? LuminaColors.midnight
                                : Color.clear
                        )
                        .clipShape(.rect(cornerRadius: LuminaSpacing.sm))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(option.value == selection ? [.isSelected] : [])
            }
        }
        .padding(LuminaSpacing.xs)
        .background(LuminaColors.parchment)
        .overlay(
            RoundedRectangle(cornerRadius: LuminaSpacing.md, style: .continuous)
                .stroke(LuminaColors.inkBlack.opacity(0.12), lineWidth: 1)
        )
        .clipShape(.rect(cornerRadius: LuminaSpacing.md))
    }
}

#Preview {
    struct Wrapper: View {
        @State private var system: HouseSystem = .placidus
        var body: some View {
            VStack {
                LuminaSegmentedControl(
                    options: [
                        (.placidus, "Placidus"),
                        (.wholeSign, "Whole-sign"),
                        (.sidereal, "Sidereal"),
                    ],
                    selection: $system
                )
                Text("Selected: \(system.rawValue)")
                    .font(LuminaTypography.body)
                    .padding(.top, LuminaSpacing.md)
            }
            .padding(LuminaSpacing.lg)
            .background(LuminaColors.parchment)
        }
    }
    return Wrapper()
}
