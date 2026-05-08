import Foundation

/// The five primary destinations of the app shell. See `docs/NAVIGATION.md`
/// for why we chose five (and not four or six) and the rationale for each
/// label, icon, and ordering.
///
/// The `rawValue` doubles as the deep-link slug (`lumina://<rawValue>`),
/// so renaming a case is a coordinated change across `LuminaDeepLink`.
enum LuminaTab: String, CaseIterable, Hashable, Codable, Sendable {
    case today
    case chart
    case palm
    case people
    case reflect

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
