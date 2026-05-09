import CoreGraphics
import SwiftUI

/// Brand corner-radius tokens. Used for cards, sheets, photo crops,
/// pill controls. SwiftLint custom rule (Phase 13) blocks raw
/// `.cornerRadius(...)` literals outside `Design/Tokens/`.
enum LuminaRadii {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let pill: CGFloat = 999
}

extension View {
    /// Brand-aware rounded clip. Prefer this over `.cornerRadius(...)` —
    /// it picks the continuous corner curve and reads from the token set.
    func luminaCornerRadius(_ radius: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}
