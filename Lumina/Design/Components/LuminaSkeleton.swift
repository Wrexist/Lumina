import SwiftUI

/// Shimmer placeholder. Used by every async screen to show layout while
/// data loads (`docs/NAVIGATION.md` §4). Honors Reduce Motion: replaces the
/// shimmer with a still neutral fill.
struct LuminaSkeleton: View {
    enum Shape {
        case line(width: CGFloat? = nil, height: CGFloat = 14)
        case block(height: CGFloat = 80)
        case circle(diameter: CGFloat = 48)
    }

    let shape: Shape

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    var body: some View {
        Group {
            switch shape {
            case .line(let width, let height):
                container.frame(width: width, height: height)
            case .block(let height):
                container.frame(maxWidth: .infinity).frame(height: height)
            case .circle(let diameter):
                container
                    .frame(width: diameter, height: diameter)
                    .clipShape(Circle())
            }
        }
        .accessibilityHidden(true)
    }

    private var container: some View {
        ZStack {
            LuminaColors.inkBlack.opacity(0.08)
            if !reduceMotion {
                LinearGradient(
                    colors: [.clear, LuminaColors.parchment.opacity(0.4), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 200)
                .onAppear {
                    withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
            }
        }
        .clipShape(.rect(cornerRadius: LuminaSpacing.xs))
    }
}

#Preview {
    VStack(alignment: .leading, spacing: LuminaSpacing.md) {
        LuminaSkeleton(shape: .line(width: 200, height: 18))
        LuminaSkeleton(shape: .line(width: 280, height: 14))
        LuminaSkeleton(shape: .block(height: 120))
        LuminaSkeleton(shape: .circle(diameter: 60))
    }
    .padding(LuminaSpacing.lg)
    .background(LuminaColors.parchment)
}
