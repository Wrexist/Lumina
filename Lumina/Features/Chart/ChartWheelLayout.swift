import Foundation

/// Pure layout maths for the natal chart wheel, split out from the SwiftUI
/// view so it can be unit-tested without a render pass.
///
/// The wheel draws each planet glyph on the radial line of its true ecliptic
/// longitude. When two or more planets are conjunct (within a few degrees)
/// their 44pt glyphs land on top of each other — illegible, and only the
/// top-most one is tappable. `staggeredRadii` fixes that by stacking a
/// cluster of conjunct glyphs at staggered radii, centred on the nominal
/// placement band, while leaving each glyph on its own true-longitude line.
enum ChartWheelLayout {
    /// Default angular gap (degrees) within which two neighbouring planets
    /// count as one cluster. ~9° tracks the conjunction orb the chart uses.
    static let clusterThreshold: Double = 9

    /// Groups planet indices that sit within `threshold` degrees of a
    /// neighbour into clusters. Handles the 0°/360° wrap by cutting the
    /// circle at its largest gap so no cluster straddles the seam. Returned
    /// indices refer to positions in `longitudes`.
    static func clusters(longitudes: [Double], threshold: Double = clusterThreshold) -> [[Int]] {
        let total = longitudes.count
        guard total > 1 else { return total == 1 ? [[0]] : [] }

        let norm = longitudes.map { normalise($0) }
        let order = (0..<total).sorted { norm[$0] < norm[$1] }

        // Cut the circle right after its largest gap, so the rotated scan
        // below is monotonic across (at most) one wrap and never splits a
        // genuine cluster across the 0°/360° seam.
        var maxGap = -1.0
        var cutAt = total - 1
        for slot in 0..<total {
            let nextSlot = (slot + 1) % total
            let here = norm[order[slot]]
            let next = norm[order[nextSlot]] + (nextSlot == 0 ? 360 : 0)
            if next - here > maxGap {
                maxGap = next - here
                cutAt = slot
            }
        }
        let rotated = (0..<total).map { order[(cutAt + 1 + $0) % total] }

        var groups: [[Int]] = []
        var current = [rotated[0]]
        for slot in 1..<total {
            let prev = norm[rotated[slot - 1]]
            var here = norm[rotated[slot]]
            if here < prev { here += 360 }
            if here - prev <= threshold {
                current.append(rotated[slot])
            } else {
                groups.append(current)
                current = [rotated[slot]]
            }
        }
        groups.append(current)
        return groups
    }

    /// One placement radius per planet, in the same order as `longitudes`.
    /// Singletons sit on `placement`; clustered glyphs fan out by `step`,
    /// centred on the band and clamped into it so they never overrun the
    /// surrounding rings.
    static func staggeredRadii(
        longitudes: [Double],
        placement: CGFloat,
        step: CGFloat,
        threshold: Double = clusterThreshold,
        band: ClosedRange<CGFloat>
    ) -> [CGFloat] {
        var radii = [CGFloat](repeating: placement, count: longitudes.count)
        for group in clusters(longitudes: longitudes, threshold: threshold) {
            let last = group.count - 1
            for (level, index) in group.enumerated() {
                let offset = (CGFloat(level) - CGFloat(last) / 2) * step
                radii[index] = clamp(placement + offset, into: band)
            }
        }
        return radii
    }

    private static func normalise(_ degrees: Double) -> Double {
        (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
    }

    private static func clamp(_ value: CGFloat, into range: ClosedRange<CGFloat>) -> CGFloat {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
