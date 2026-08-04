import SwiftUI

/// Brand color palette. Never use hex literals or `Color(red:green:blue:)`
/// outside this file — `.swiftlint.yml` enforces this with `no_hex_color_literals`.
enum LuminaColors {
    static let inkBlack = color(hex: "#1A1A1F")
    static let parchment = color(hex: "#F5F0E6")
    static let celestialBlue = color(hex: "#3D5A8C")
    static let mutedGold = color(hex: "#C9A96E")
    /// Gold intended for TEXT and glyphs on light surfaces. `mutedGold` as
    /// text on `parchment` is only ~2:1 (fails WCAG AA), so use `goldInk`
    /// (~4.96:1 on `parchment`) whenever a gold word or symbol must be read.
    /// Keep `mutedGold` for fills, strokes, and dots — decoration, not text.
    static let goldInk = color(hex: "#806326")
    static let midnight = color(hex: "#0B1437")
    static let blush = color(hex: "#E5C8C2")
    /// Error / destructive accent. A muted oxblood that keeps the editorial
    /// tone while clearing WCAG AA (~6.9:1) for body text on `parchment`
    /// and for `parchment` text on an `error` fill.
    static let error = color(hex: "#9B2C2C")

    // MARK: - Chart wheel strokes
    //
    // The wheel draws on `midnight`, where the palette's parchment-tuned
    // accents wash out: `celestialBlue` measures ~1.6:1 there and `error`
    // ~1.9:1. These two are picked for that surface specifically — see
    // `ChartWheelView.aspectColor`.

    /// Sextiles and trines. A lifted celestial blue — 8.7:1 on `midnight`,
    /// against 2.6:1 for the parchment-tuned `celestialBlue` it replaces.
    static let aspectHarmonious = color(hex: "#8FB8E8")
    /// Squares and oppositions. A warm coral, 6.1:1 on `midnight`, against
    /// 2.4:1 for `error`.
    static let aspectTense = color(hex: "#E0777A")

    private static func color(hex: String) -> Color {
        let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&rgb)
        let red = Double((rgb & 0xFF_0000) >> 16) / 255.0
        let green = Double((rgb & 0x00_FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x00_00FF) / 255.0
        return Color(.sRGB, red: red, green: green, blue: blue, opacity: 1.0)
    }
}
