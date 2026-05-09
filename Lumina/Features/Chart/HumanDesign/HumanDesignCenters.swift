import SwiftUI

/// The 9 Human Design centers and the canonical gate ownership.
/// Together they cover all 64 gates exactly once.
///
/// Center positions on the bodygraph are normalised to a 0–1 coordinate
/// space (0,0 = top-leading) so the renderer can scale to any frame.
enum HumanDesignCenter: String, CaseIterable, Sendable, Identifiable {
    case head
    case ajna
    case throat
    case g
    case heart
    case solarPlexus
    case sacral
    case spleen
    case root

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .head: "Head"
        case .ajna: "Ajna"
        case .throat: "Throat"
        case .g: "G Center"
        case .heart: "Heart"
        case .solarPlexus: "Solar Plexus"
        case .sacral: "Sacral"
        case .spleen: "Spleen"
        case .root: "Root"
        }
    }

    /// Gates owned by this center. Exhaustive and disjoint across the
    /// nine centers — together they enumerate all 64 gates exactly once.
    var gates: Set<Int> {
        switch self {
        case .head: [61, 63, 64]
        case .ajna: [4, 11, 17, 24, 43, 47]
        case .throat: [8, 12, 16, 20, 23, 31, 33, 35, 45, 56, 62]
        case .g: [1, 2, 7, 10, 13, 15, 25, 46]
        case .heart: [21, 26, 40, 51]
        case .solarPlexus: [6, 22, 30, 36, 37, 49, 55]
        case .sacral: [3, 5, 9, 14, 27, 29, 34, 42, 59]
        case .spleen: [18, 28, 32, 44, 48, 50, 57]
        case .root: [19, 38, 39, 41, 52, 53, 54, 58, 60]
        }
    }

    /// Brand color the center fills with when defined. Hollow when undefined.
    var fillColor: Color {
        switch self {
        case .head, .ajna: LuminaColors.celestialBlue
        case .throat: LuminaColors.mutedGold
        case .g: LuminaColors.celestialBlue
        case .heart: LuminaColors.blush
        case .solarPlexus: LuminaColors.blush
        case .sacral: LuminaColors.blush
        case .spleen: LuminaColors.celestialBlue
        case .root: LuminaColors.mutedGold
        }
    }

    /// Bodygraph layout — normalised position + size in [0,1] space.
    /// Anchor is top-leading. Sized to roughly match the canonical
    /// HD bodygraph proportions (the actual HD shapes are triangles for
    /// Head/Ajna/Solar Plexus/Spleen and squares for the rest, but we
    /// render all as rounded rectangles for now to keep the renderer
    /// simple — Phase 8 polish swaps in the real triangle paths).
    var layoutFrame: CGRect {
        switch self {
        case .head: CGRect(x: 0.40, y: 0.04, width: 0.20, height: 0.10)
        case .ajna: CGRect(x: 0.36, y: 0.18, width: 0.28, height: 0.10)
        case .throat: CGRect(x: 0.34, y: 0.32, width: 0.32, height: 0.10)
        case .g: CGRect(x: 0.36, y: 0.46, width: 0.28, height: 0.12)
        case .heart: CGRect(x: 0.66, y: 0.50, width: 0.16, height: 0.08)
        case .spleen: CGRect(x: 0.10, y: 0.62, width: 0.22, height: 0.10)
        case .solarPlexus: CGRect(x: 0.66, y: 0.62, width: 0.22, height: 0.10)
        case .sacral: CGRect(x: 0.34, y: 0.62, width: 0.32, height: 0.12)
        case .root: CGRect(x: 0.34, y: 0.82, width: 0.32, height: 0.12)
        }
    }
}
