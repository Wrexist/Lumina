import SwiftUI

/// Brand typography. Fonts are not yet bundled (license blocker — see TASK.md).
/// Until the font files land in `Lumina/Resources/Fonts/`, every entry falls back
/// to a system equivalent so the app renders. Once licensed, replace `.system(...)`
/// with `Font.custom(BundledFont.<name>.rawValue, size: ...)`.
enum LuminaTypography {
    static let display = Font.system(size: 40, weight: .regular, design: .serif).italic()
    static let heading = Font.system(size: 28, weight: .regular, design: .serif)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyLight = Font.system(size: 17, weight: .light, design: .default)
    static let caption = Font.system(size: 13, weight: .regular, design: .default)
    static let mono = Font.system(size: 14, weight: .regular, design: .monospaced)
}

/// Names of font files expected in `Lumina/Resources/Fonts/`.
/// Used once the type license is resolved — see TASK.md "Blockers".
enum BundledFont: String {
    case ppEditorialNewItalic = "PPEditorialNew-Italic"
    case ppEditorialNewRegular = "PPEditorialNew-Regular"
    case sohneRegular = "Sohne-Buch"
    case sohneLeicht = "Sohne-Leicht"
    case gtAmericaMono = "GT-America-Mono-Regular"
}
