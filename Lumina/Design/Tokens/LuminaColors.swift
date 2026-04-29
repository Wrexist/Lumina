import SwiftUI

/// Brand color palette. Never use hex literals or `Color(red:green:blue:)`
/// outside this file — `.swiftlint.yml` enforces this with `no_hex_color_literals`.
enum LuminaColors {
    static let inkBlack = Color(hex: "#1A1A1F")
    static let parchment = Color(hex: "#F5F0E6")
    static let celestialBlue = Color(hex: "#3D5A8C")
    static let mutedGold = Color(hex: "#C9A96E")
    static let midnight = Color(hex: "#0B1437")
    static let blush = Color(hex: "#E5C8C2")
}

private extension Color {
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&rgb)
        let red = Double((rgb & 0xFF_0000) >> 16) / 255.0
        let green = Double((rgb & 0x00_FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x00_00FF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1.0)
    }
}
