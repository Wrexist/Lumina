import Foundation

/// Single source of truth for inbound URL routing. Every `lumina://...` URL
/// resolves to one case, every case has tests, and no other file calls
/// `URL`-parsing for app navigation. See `docs/NAVIGATION.md` §7.
enum LuminaDeepLink: Equatable, Sendable {
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
    static func from(url: URL) -> LuminaDeepLink? {
        guard url.scheme == "lumina" else { return nil }
        // SwiftUI gives us URLs where the host is the first path component;
        // normalise both shapes (`lumina://chart` and `lumina:///chart`).
        let path = (url.host.map { [$0] } ?? []) + url.pathComponents.filter { $0 != "/" }
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
