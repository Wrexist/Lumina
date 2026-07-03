import Foundation

/// The primary destinations of the app shell. See `docs/NAVIGATION.md`
/// for the rationale for each label, icon, and ordering.
///
/// The `rawValue` doubles as the deep-link slug (`lumina://<rawValue>`),
/// so renaming a case is a coordinated change across `LuminaDeepLink`.
///
/// `.palm` is retained as a case (deep links and `PalmHubView` still resolve)
/// but is **not** in `visible`: palm scanning isn't shipped for 1.0, so the
/// shell shows a focused four-tab bar. Re-add `.palm` to `visible` to restore
/// the tab the moment the on-device capture pipeline lands.
enum LuminaTab: String, CaseIterable, Hashable, Codable, Sendable {
    case today
    case chart
    case palm
    case people
    case reflect

    /// The tabs actually shown in the shell, in order. Excludes `.palm` until
    /// the palm-reading feature ships (see the type doc).
    static let visible: [LuminaTab] = [.today, .chart, .people, .reflect]

    /// User-facing short name. Localized at the call site via String Catalogs;
    /// the English source-of-truth lives here and is intentionally ≤ 7 chars.
    var title: String {
        switch self {
        case .today: "Today"
        case .chart: "Chart"
        case .palm: "Palm"
        case .people: "People"
        case .reflect: "Reflect"
        }
    }

    /// SF Symbol used as the tab icon. We pair custom brand glyphs (in the
    /// shipped asset catalog) with these system fallbacks so SwiftUI Previews
    /// render correctly without the asset bundle.
    var systemImage: String {
        switch self {
        case .today: "sun.max"
        case .chart: "circle.dotted"
        case .palm: "hand.raised"
        case .people: "person.2"
        case .reflect: "moonphase.first.quarter"
        }
    }
}
