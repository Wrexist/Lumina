import Foundation

/// Single source of truth for inbound URL routing. Every `lumina://...` URL
/// and every `https://lumina.app/...` universal link resolves to one case,
/// every case has tests, and no other file calls `URL`-parsing for app
/// navigation. See `docs/NAVIGATION.md` §7 and
/// `docs/CAPABILITIES-PLAN.md` §4.
enum LuminaDeepLink: Equatable, Sendable {
    /// The universal-link host this parser and QR/share generation must agree
    /// on. Kept here so both sides stay in sync if the domain ever changes.
    static let universalLinkHost = "lumina.app"

    case today
    case chart(planet: String?)
    case palmScan
    case palmHistory
    case people(friendID: UUID?)
    case acceptShare(payload: String)
    case reflect(entryID: UUID?)
    case settings
    case help(topicID: String?)

    /// Tab the link should land on. `settings` and `help` open as a sheet
    /// on top of the current tab and therefore have no own tab.
    var tab: LuminaTab? {
        switch self {
        case .today: .today
        case .chart: .chart
        case .palmScan, .palmHistory: .palm
        case .people, .acceptShare: .people
        case .reflect: .reflect
        case .settings, .help: nil
        }
    }

    /// Returns `nil` for any URL that isn't a Lumina deep link or isn't
    /// understood. Callers fall back to a default route (typically `.today`).
    ///
    /// Accepts either the custom `lumina://...` scheme (any host/path) or a
    /// `https://lumina.app/...` universal link — both feed the exact same
    /// path-parsing below, so adding a new route only ever needs one switch
    /// statement, not one per scheme.
    static func from(url: URL) -> LuminaDeepLink? {
        guard let path = routePath(for: url) else { return nil }
        guard let head = path.first else { return nil }
        let tail = Array(path.dropFirst())

        switch head {
        case "today": return .today
        case "chart": return parseChart(tail: tail)
        case "palm": return parsePalm(tail: tail)
        case "people": return parsePeople(tail: tail)
        case "share": return parseShare(tail: tail)
        case "reflect": return parseReflect(tail: tail)
        case "settings": return .settings
        case "help": return parseHelp(tail: tail)
        default: return nil
        }
    }

    // MARK: - Scheme handling

    /// Builds the route's path components (e.g. `["chart", "planet", "Mars"]`)
    /// for a supported URL, or `nil` if the scheme/host combination isn't a
    /// Lumina link at all. This is the only place the two supported shapes
    /// (`lumina://...` and `https://lumina.app/...`) diverge — everything
    /// past this point is one shared parser.
    private static func routePath(for url: URL) -> [String]? {
        let components = url.pathComponents.filter { $0 != "/" }
        switch url.scheme {
        case "lumina":
            // SwiftUI gives us URLs where the host is the first path
            // component; normalise both shapes (`lumina://chart` and
            // `lumina:///chart`).
            return (url.host.map { [$0] } ?? []) + components
        case "https":
            guard url.host == Self.universalLinkHost else { return nil }
            // Here the host is the real domain, not a route component —
            // the route lives entirely in the path (`/chart/...`).
            return components
        default:
            return nil
        }
    }

    // MARK: - Component parsers

    private static func parseChart(tail: [String]) -> LuminaDeepLink {
        if tail.count >= 2, tail[0] == "planet" {
            return .chart(planet: tail[1])
        }
        return .chart(planet: nil)
    }

    private static func parsePalm(tail: [String]) -> LuminaDeepLink {
        switch tail.first {
        case "scan": .palmScan
        case "history", nil: .palmHistory
        default: .palmHistory
        }
    }

    private static func parsePeople(tail: [String]) -> LuminaDeepLink {
        if let raw = tail.first, let uuid = UUID(uuidString: raw) {
            return .people(friendID: uuid)
        }
        return .people(friendID: nil)
    }

    private static func parseShare(tail: [String]) -> LuminaDeepLink {
        guard let payload = tail.first, !payload.isEmpty else { return .today }
        return .acceptShare(payload: payload)
    }

    private static func parseReflect(tail: [String]) -> LuminaDeepLink {
        if let raw = tail.first, raw != "today", let uuid = UUID(uuidString: raw) {
            return .reflect(entryID: uuid)
        }
        return .reflect(entryID: nil)
    }

    private static func parseHelp(tail: [String]) -> LuminaDeepLink {
        .help(topicID: tail.first)
    }
}
