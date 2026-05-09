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
            let data = try Data(contentsOf: url)
            let raw = try JSONDecoder().decode([GlossaryEntry].self, from: data)
            entries = Dictionary(uniqueKeysWithValues: raw.map { ($0.key, $0) })
            isLoaded = true
            logger.info("loaded \(self.entries.count) glossary entries")
        } catch {
            logger.error("failed to decode glossary: \(error.localizedDescription)")
            isLoaded = true
        }
    }

    /// Lookup is case-insensitive on the term; falls back to `nil` if not
    /// found. The view renders the term as plain text in that case.
    func entry(for term: String) -> GlossaryEntry? {
        let key = term.lowercased()
        return entries[key]
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
}
