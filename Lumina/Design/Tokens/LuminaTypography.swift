import SwiftUI

/// Brand typography. Fonts are not yet bundled (license blocker — see TASK.md).
/// Until the font files land in `Lumina/Resources/Fonts/`, every entry falls back
/// to a system equivalent so the app renders.
///
/// Each token is anchored to a Dynamic Type text style so it scales with the
/// user's preferred content size (a fixed `size:` would not — an accessibility
/// failure for low-vision users; see `docs/NAVIGATION.md` §17). Once the type
/// license is resolved, swap to `Font.custom(_:size:relativeTo:)` keyed to the
/// same text styles to preserve scaling.
enum LuminaTypography {
    static let display = Font.system(.largeTitle, design: .serif).italic()
    static let heading = Font.system(.title, design: .serif)
    static let body = Font.system(.body)
    static let bodyLight = Font.system(.body).weight(.light)
    static let caption = Font.system(.footnote)
    static let mono = Font.system(.subheadline, design: .monospaced)
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
