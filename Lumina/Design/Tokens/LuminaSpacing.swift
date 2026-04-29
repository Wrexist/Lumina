import CoreGraphics

/// 8-pt grid spacing tokens. `.swiftlint.yml`'s `no_magic_spacing_numbers`
/// enforces using these constants over numeric literals in `padding` /
/// `frame` / `spacing` modifiers (≥10).
enum LuminaSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
