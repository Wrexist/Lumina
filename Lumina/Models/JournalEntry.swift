import Foundation
import SwiftData

/// SwiftData model for a single Reflect entry. Stored locally only —
/// journal text never leaves the device in v1 (privacy promise; see
/// `docs/NAVIGATION.md` §11 and `ROADMAP.md` Phase 9).
///
/// Schema iteration ships through a real `SchemaMigrationPlan` once a
/// new field set is needed. For v1, optional fields default to `nil` so
/// historical entries still decode if we add columns later.
@Model
final class JournalEntry {
    /// Stable id for `Identifiable` and external references (e.g. deep
    /// links into a specific entry from a notification). Unique so a
    /// deep-link lookup by UUID can never resolve to two rows.
    @Attribute(.unique) var id: UUID
    /// The day the entry belongs to. We bucket per local-day; not the
    /// minute-level write timestamp.
    var date: Date
    /// The reflective prompt that was offered when the user opened the
    /// editor. Captured so an entry remains readable even if prompts
    /// rotate later.
    var prompt: String
    /// User's reflection text.
    var body: String
    /// Deterministic transit key — `JournalPromptGenerator` uses this to
    /// memoise prompts and the Phase-9 monthly pattern detector groups
    /// by it. Empty string is fine; it just means "no transit-keyed
    /// pattern yet".
    var transitKey: String
    /// Cached word count. Recomputed on every save so we don't recount
    /// in the calendar / list view.
    var wordCount: Int
    /// Created-at timestamp; differs from `date` when a backdated entry
    /// is written for a previous day.
    var createdAt: Date
    /// Last edit timestamp.
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date = .now,
        prompt: String,
        body: String = "",
        transitKey: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.prompt = prompt
        self.body = body
        self.transitKey = transitKey
        self.wordCount = JournalEntry.countWords(in: body)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func countWords(in text: String) -> Int {
        text
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .count
    }

    /// Re-counts words and bumps `updatedAt`. Called from the editor's
    /// debounced auto-save.
    func apply(body newBody: String) {
        body = newBody
        wordCount = JournalEntry.countWords(in: newBody)
        updatedAt = .now
    }
}
