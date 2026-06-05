import Foundation

/// Generates the daily reflective prompt. Phase 9 of `ROADMAP.md` keys
/// each prompt to the active transit so the same transit re-uses the
/// same prompt — the LLM-backed transit-grounded variant ships with the
/// daily-reading pipeline (Phase 5).
///
/// For now the generator is fully deterministic: a small, hand-written
/// pool of prompts keyed by date so the same day always produces the
/// same prompt across the app (calendar, today's prompt card,
/// notification copy). When the real transit pipeline lands, swap the
/// `for(date:)` body to look up by transitKey and fall back to this
/// pool if the LLM call fails.
struct JournalPromptGenerator {
    static let shared = JournalPromptGenerator()

    /// Pool of prompts. Hand-written, no astrology jargon, no instruction
    /// to perform — every prompt opens a question, never a directive.
    private static let pool: [String] = [
        "What's something true about today that wasn't true last week?",
        "Where in your body do you notice today's mood?",
        "What's one small thing you'd like to remember about right now?",
        "Who has been on your mind lately, and why?",
        "What's a thought you've been turning over but not writing down?",
        "If today were a weather pattern, what would it be?",
        "What's a question you don't quite know how to ask out loud?",
        "What's a small kindness you noticed today — yours or someone else's?",
        "What part of yourself has been quiet lately?",
        "What feels uncertain, and how are you carrying that?",
        "What's something you want to set down before tomorrow?",
        "Where did you feel like yourself today?",
        "What boundary did you hold (or wish you had held)?",
        "What's a feeling you can't quite name yet?",
    ]

    /// A "sensitive" alternative when the day's transit is heavy
    /// (Pluto / Saturn squares, eclipses, etc). Phase 9 gives the user
    /// a gentle tap-out from the heavier prompt.
    static let softerPool: [String] = [
        "What's the smallest good thing that happened today?",
        "What sound, image, or texture brought you ease today?",
        "Who or what would you like to thank, even silently?",
        "What's something simple that you'd like to do tomorrow?",
    ]

    /// Returns the prompt for a given date. Deterministic — same date
    /// returns the same prompt across the app.
    func prompt(for date: Date, calendar: Calendar = .current) -> String {
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
        let index = day % Self.pool.count
        return Self.pool[index]
    }

    /// The day's prompt keyed to the strongest current transit (so the Reflect
    /// prompt responds to the real sky), falling back to the date-keyed pool
    /// when no transit is available. Transits are expected tightest-first.
    func prompt(forTransits transits: [TransitReading], on date: Date, calendar: Calendar = .current) -> String {
        guard let top = TransitPrompt.strongest(in: transits) else {
            return prompt(for: date, calendar: calendar)
        }
        return TransitPrompt.prompt(for: top)
    }

    /// Returns the softer-prompt counterpart for the same date so the
    /// user's "skip — give me a softer prompt" tap is also deterministic.
    func softerPrompt(for date: Date, calendar: Calendar = .current) -> String {
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
        let index = day % Self.softerPool.count
        return Self.softerPool[index]
    }

    /// Stable key used by `JournalEntry.transitKey` and the Phase-9
    /// monthly pattern detector. Today the key is just the date; once the
    /// real transit pipeline lands it becomes `transit:<top-3-hash>`.
    func transitKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "date:\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    /// The transit-keyed counterpart so an entry created from a transit-tied
    /// prompt groups by that transit; falls back to the date key otherwise.
    func transitKey(forTransits transits: [TransitReading], on date: Date, calendar: Calendar = .current) -> String {
        guard let top = TransitPrompt.strongest(in: transits) else {
            return transitKey(for: date, calendar: calendar)
        }
        return TransitPrompt.key(for: top)
    }
}
