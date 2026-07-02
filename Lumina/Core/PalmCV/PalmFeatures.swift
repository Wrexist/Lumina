import Foundation

/// Geometric features extracted on-device from a hand-pose observation — the
/// only thing that would ever leave the device (never the photo; see CLAUDE.md
/// critical rules). All values share one uniform coordinate space (pixels, in
/// the Vision adapter's case), so only their *ratios* carry meaning.
struct PalmFeatures: Equatable, Sendable {
    /// Span across the finger bases (index MCP → little MCP).
    let palmWidth: Double
    /// Wrist → middle-finger base.
    let palmLength: Double
    /// Mean finger length (base → tip), across index/middle/ring/little.
    let averageFingerLength: Double
}
