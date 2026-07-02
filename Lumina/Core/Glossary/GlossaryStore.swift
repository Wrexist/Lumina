import Foundation
import OSLog

/// Loads and serves entries from `Resources/Glossary.json`. Lazy — the
/// dictionary isn't read until the first lookup. Read-only after load.
///
/// Every astrology, palmistry, or Human Design term that appears in
/// shipped UI body copy must resolve here. A CI script (Phase 13)
/// fails the build if a known term is rendered as plain `Text`.
@MainActor
@Observable
final class GlossaryStore {
    static let shared = GlossaryStore()

    private let logger = Logger(subsystem: "app.lumina.ios", category: "Glossary")
    private(set) var entries: [String: GlossaryEntry] = [:]
    /// Canonical keys *plus* lowercased aliases, all pointing at the same
    /// entry. Kept separate from `entries` so UI that lists `entries.values`
    /// (the Glossary screen) never shows an entry once per alias.
    private var lookup: [String: GlossaryEntry] = [:]
    private(set) var isLoaded = false

    init() {}

    /// Load from the app bundle. Safe to call multiple times — only the
    /// first call performs the JSON decode.
    func loadIfNeeded(bundle: Bundle = .main) {
        guard !isLoaded else { return }
        guard let url = bundle.url(forResource: "Glossary", withExtension: "json") else {
            logger.error("Glossary.json not found in bundle")
            isLoaded = true
            return
        }
        do {
            try load(data: Data(contentsOf: url))
            logger.info("loaded \(self.entries.count) glossary entries")
        } catch {
            logger.error("failed to decode glossary: \(error.localizedDescription)")
            isLoaded = true
        }
    }

    /// Decode and index a glossary payload. Internal so tests can exercise
    /// alias resolution with fixture JSON instead of the app bundle.
    func load(data: Data) throws {
        let raw = try JSONDecoder().decode([GlossaryEntry].self, from: data)
        // A duplicate key in the JSON is a content bug, not a crash — keep
        // the first entry rather than trapping in `uniqueKeysWithValues`.
        entries = Dictionary(raw.map { ($0.key, $0) }, uniquingKeysWith: { first, _ in first })
        // Aliases resolve too, but never shadow another entry's canonical key.
        var lookup = entries
        for entry in raw {
            for alias in entry.aliases {
                let aliasKey = alias.lowercased()
                if lookup[aliasKey] == nil { lookup[aliasKey] = entry }
            }
        }
        self.lookup = lookup
        isLoaded = true
    }

    /// Lookup is case-insensitive on the term (canonical key or alias);
    /// falls back to `nil` if not found. The view renders the term as plain
    /// text in that case.
    func entry(for term: String) -> GlossaryEntry? {
        let key = term.lowercased()
        return lookup[key]
    }
}

struct GlossaryEntry: Codable, Hashable, Sendable, Identifiable {
    enum Category: String, Codable, Sendable, CaseIterable {
        case astrology
        case humanDesign
        case palmistry
        case general
    }

    /// Lowercased canonical key. Multiple display forms map to the same
    /// entry via the `aliases` array.
    let key: String
    let displayName: String
    let category: Category
    let summary: String
    let body: String
    var aliases: [String] = []

    var id: String { key }

    /// Hand-rolled so `aliases` is genuinely optional in the JSON — the
    /// synthesized `Decodable` ignores the `= []` default and would fail the
    /// whole glossary decode over one entry with no "aliases" key.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        displayName = try container.decode(String.self, forKey: .displayName)
        category = try container.decode(Category.self, forKey: .category)
        summary = try container.decode(String.self, forKey: .summary)
        body = try container.decode(String.self, forKey: .body)
        aliases = try container.decodeIfPresent([String].self, forKey: .aliases) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case key, displayName, category, summary, body, aliases
    }
}
