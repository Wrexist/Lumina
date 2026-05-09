import SwiftUI

/// Bodygraph renderer. Centers are rounded rectangles on a normalised
/// 0–1 layout space; defined centers fill with the brand color, undefined
/// centers stay hollow with a stroke. Tap a center to see a detail
/// sheet with which gates lit it up.
///
/// We deliberately do NOT render Type, Profile, or Authority here — they
/// require the design-side chart (88° solar arc back) which the backend
/// doesn't yet expose. The "see what's missing" footer makes that
/// transparent.
struct BodygraphView: View {
    let activation: HumanDesignActivation
    var onTapCenter: ((HumanDesignCenter) -> Void)?

    static let designSideMissingNote = "Type, Profile, and Authority require the design-side chart (88° before birth). That endpoint ships with Phase 8 — until then we render only the personality-side activations."

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height * 0.9)
            ZStack(alignment: .topLeading) {
                ForEach(HumanDesignCenter.allCases) { center in
                    centerView(for: center, in: size)
                }
            }
            .frame(width: size, height: size, alignment: .topLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(0.9, contentMode: .fit)
        .accessibilityLabel("Human Design bodygraph")
    }

    private func centerView(for center: HumanDesignCenter, in size: CGFloat) -> some View {
        let frame = center.layoutFrame
        let isDefined = activation.definedCenters.contains(center)
        let width = frame.width * size
        let height = frame.height * size
        return Button {
            Haptics.light.play()
            onTapCenter?(center)
        } label: {
            RoundedRectangle(cornerRadius: LuminaRadii.xs, style: .continuous)
                .fill(isDefined ? center.fillColor : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: LuminaRadii.xs, style: .continuous)
                        .stroke(LuminaColors.inkBlack.opacity(isDefined ? 0.3 : 0.5), lineWidth: 1)
                )
                .overlay(
                    Text(center.displayName)
                        .font(LuminaTypography.caption)
                        .foregroundStyle(isDefined ? LuminaColors.parchment : LuminaColors.inkBlack.opacity(0.7))
                        .padding(LuminaSpacing.xs)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.6)
                )
        }
        .buttonStyle(.plain)
        .frame(width: width, height: height)
        .position(
            x: frame.minX * size + width / 2,
            y: frame.minY * size + height / 2
        )
        .accessibilityLabel("\(center.displayName) — \(isDefined ? "defined" : "open")")
    }
}
