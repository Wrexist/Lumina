import Foundation

/// One question in the daily "know your chart" quiz. `insight` is the honest
/// teaching line revealed after the user answers — the educational payoff,
/// grounded in their real placements.
struct ChartQuizQuestion: Equatable, Sendable {
    let prompt: String
    let options: [String]
    let answerIndex: Int
    let insight: String
}

/// SplitMix64 — a tiny deterministic PRNG. `SystemRandomNumberGenerator` is
/// seedless, and the quiz must produce the *same* questions for the same
/// (chart, seed) so the daily set is stable all day and unit-testable.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }
}

/// Pure, deterministic question generator for the "know your chart" mini-game.
/// Every question is answerable from the real chart — never trivia the user's
/// own sky can't verify. Templates that the chart lacks data for are simply
/// skipped, so callers may receive fewer questions than requested.
enum ChartQuizEngine {
    // MARK: - Public API

    /// Deterministic for a given (chart, seed): the same inputs always yield
    /// the same questions, options, and order.
    static func questions(from chart: NatalChart, count: Int = 3, seed: UInt64) -> [ChartQuizQuestion] {
        var generator = SeededGenerator(seed: seed)
        var pool = [
            signQuestion(from: chart, using: &generator),
            retrogradeQuestion(from: chart, using: &generator),
            tightestAspectQuestion(from: chart, using: &generator),
            elementQuestion(from: chart, using: &generator),
        ].compactMap { $0 }
        pool.shuffle(using: &generator)
        return Array(pool.prefix(max(count, 0)))
    }

    /// Same seed all day, a new one tomorrow — the quiz refreshes with the
    /// sky, which is the whole anticipation loop.
    static func dailySeed(for date: Date = .now, calendar: Calendar = .current) -> UInt64 {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let year = UInt64(max(parts.year ?? 0, 0))
        let month = UInt64(max(parts.month ?? 0, 0))
        let day = UInt64(max(parts.day ?? 0, 0))
        return year &* 10_000 &+ month &* 100 &+ day
    }

    /// Canonical "yyyy-MM-dd" key for the once-per-day gate. Component-based
    /// (not `DateFormatter`) so it's cheap, deterministic, and calendar-correct.
    static func dayString(for date: Date = .now, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// Warm, never-negative score copy. Missed questions are discoveries
    /// waiting on the wheel, not failures.
    static func verdict(correct: Int, total: Int) -> String {
        guard total > 0 else {
            return "Your chart is still gathering its questions — come back tomorrow."
        }
        if correct >= total {
            return "You know your sky. ✦"
        }
        if correct == total - 1 {
            return "Close to your chart — one surprise today."
        }
        if correct > 0 {
            return "A few surprises today — your chart clearly still has stories for you."
        }
        return "Your chart still has secrets for you — the wheel above knows them all."
    }

    // MARK: - Templates

    /// "Which sign is your <planet>?" — available whenever the chart has at
    /// least one planet. Options are the correct sign plus three distinct
    /// other signs, seeded-shuffled.
    private static func signQuestion(
        from chart: NatalChart,
        using generator: inout SeededGenerator
    ) -> ChartQuizQuestion? {
        guard let planet = chart.planets.randomElement(using: &generator) else { return nil }
        let sign = ChartGlyphs.sign(forLongitude: planet.longitude)
        var others = ChartGlyphs.signOrder.filter { $0 != sign }
        others.shuffle(using: &generator)
        var options = Array(others.prefix(3)) + [sign]
        options.shuffle(using: &generator)
        guard let answerIndex = options.firstIndex(of: sign) else { return nil }
        return ChartQuizQuestion(
            prompt: "Which sign is your \(planet.planet)?",
            options: options,
            answerIndex: answerIndex,
            insight: "Your \(planet.planet) in \(sign) \(signInsightPhrase(for: planet.planet))"
        )
    }

    /// "Which of these planets is retrograde in your chart?" — only when the
    /// chart has at least one retrograde *and* three direct planets to act as
    /// distractors, so the answer is never guessable by elimination.
    private static func retrogradeQuestion(
        from chart: NatalChart,
        using generator: inout SeededGenerator
    ) -> ChartQuizQuestion? {
        let retrograde = chart.planets.filter(\.isRetrograde)
        let direct = chart.planets.filter { !$0.isRetrograde }
        guard let answer = retrograde.randomElement(using: &generator), direct.count >= 3 else { return nil }
        var distractors = direct.map(\.planet)
        distractors.shuffle(using: &generator)
        var options = Array(distractors.prefix(3)) + [answer.planet]
        options.shuffle(using: &generator)
        guard let answerIndex = options.firstIndex(of: answer.planet) else { return nil }
        return ChartQuizQuestion(
            prompt: "Which of these planets is retrograde in your chart?",
            options: options,
            answerIndex: answerIndex,
            insight: "\(answer.planet) was moving retrograde when you were born — its themes turn inward, more reflective than delayed."
        )
    }

    /// "Your tightest aspect is between which pair?" — from the minimum-orb
    /// aspect. Needs at least one aspect and one distractor pair to be a
    /// real question.
    private static func tightestAspectQuestion(
        from chart: NatalChart,
        using generator: inout SeededGenerator
    ) -> ChartQuizQuestion? {
        guard let tightest = chart.aspects.min(by: { $0.orb < $1.orb }) else { return nil }
        // Skip on an exact-orb tie: a second equally-tight aspect would be a
        // second correct answer, so a user tapping it would be wrongly marked.
        guard chart.aspects.filter({ $0.orb == tightest.orb }).count == 1 else { return nil }
        let correct = pairLabel(tightest.planet1, tightest.planet2)
        let distractors = distractorPairs(in: chart, excluding: correct, using: &generator)
        guard !distractors.isEmpty else { return nil }
        var options = distractors + [correct]
        options.shuffle(using: &generator)
        guard let answerIndex = options.firstIndex(of: correct) else { return nil }
        let orbText = String(format: "%.1f", tightest.orb)
        return ChartQuizQuestion(
            prompt: "Your tightest aspect is between which pair?",
            options: options,
            answerIndex: answerIndex,
            insight: "\(correct) form \(article(for: tightest.type)) \(tightest.type.rawValue) within \(orbText)° — the loudest conversation in your chart."
        )
    }

    /// "Which element leads your chart?" — a plain, checkable tally of planet
    /// signs by element (unweighted, so the user can verify it on the wheel).
    /// Ties break by the traditional element order, keeping the answer stable.
    private static func elementQuestion(
        from chart: NatalChart,
        using generator: inout SeededGenerator
    ) -> ChartQuizQuestion? {
        guard !chart.planets.isEmpty else { return nil }
        var counts: [String: Int] = [:]
        for planet in chart.planets {
            counts[element(of: ChartGlyphs.sign(forLongitude: planet.longitude)), default: 0] += 1
        }
        let elements = ["Fire", "Earth", "Air", "Water"]
        var leading = "Fire"
        var best = -1
        for candidate in elements where (counts[candidate] ?? 0) > best {
            best = counts[candidate] ?? 0
            leading = candidate
        }
        // Skip on a tally tie (e.g. Fire 4 / Air 4): two elements equally
        // "lead", so tapping the other one shouldn't be marked wrong.
        guard elements.filter({ (counts[$0] ?? 0) == best }).count == 1 else { return nil }
        var options = elements
        options.shuffle(using: &generator)
        guard let answerIndex = options.firstIndex(of: leading) else { return nil }
        let verb = best == 1 ? "sits" : "sit"
        return ChartQuizQuestion(
            prompt: "Which element leads your chart?",
            options: options,
            answerIndex: answerIndex,
            insight: "\(best) of your \(chart.planets.count) planets \(verb) in \(leading.lowercased()) signs — \(elementInsightPhrase(for: leading))"
        )
    }

    // MARK: - Helpers

    /// Distinct distractor pair labels: the chart's other aspected pairs first
    /// (they feel plausible), topped up from remaining planet pairings when
    /// the chart carries fewer than three other aspects.
    private static func distractorPairs(
        in chart: NatalChart,
        excluding correct: String,
        using generator: inout SeededGenerator
    ) -> [String] {
        var seen: Set<String> = [correct]
        var fromAspects: [String] = []
        for aspect in chart.aspects {
            let label = pairLabel(aspect.planet1, aspect.planet2)
            if seen.insert(label).inserted { fromAspects.append(label) }
        }
        fromAspects.shuffle(using: &generator)
        var pairs = Array(fromAspects.prefix(3))
        guard pairs.count < 3 else { return pairs }
        var filler: [String] = []
        let names = chart.planets.map(\.planet)
        for first in names.indices {
            for second in names.indices where second > first {
                let label = pairLabel(names[first], names[second])
                if seen.insert(label).inserted { filler.append(label) }
            }
        }
        filler.shuffle(using: &generator)
        pairs.append(contentsOf: filler.prefix(3 - pairs.count))
        return pairs
    }

    /// Canonical "A & B" label — ordered by the traditional planet order so
    /// the same pairing always reads the same way regardless of source order.
    private static func pairLabel(_ first: String, _ second: String) -> String {
        let order = ChartGlyphs.planetOrder
        let firstRank = order.firstIndex(of: first) ?? order.count
        let secondRank = order.firstIndex(of: second) ?? order.count
        return firstRank <= secondRank ? "\(first) & \(second)" : "\(second) & \(first)"
    }

    private static func article(for type: AspectType) -> String {
        type == .opposition ? "an" : "a"
    }

    private static func element(of sign: String) -> String {
        switch sign {
        case "Aries", "Leo", "Sagittarius": "Fire"
        case "Taurus", "Virgo", "Capricorn": "Earth"
        case "Gemini", "Libra", "Aquarius": "Air"
        default: "Water"
        }
    }

    private static func signInsightPhrase(for planet: String) -> String {
        switch planet {
        case "Sun": "shapes the core of who you are becoming."
        case "Moon": "colors how you process feeling."
        case "Mercury": "sets the rhythm of how you think and speak."
        case "Venus": "shows what you reach for in love and beauty."
        case "Mars": "fuels how you act when something matters."
        case "Jupiter": "points to where life opens up for you."
        case "Saturn": "marks where patience builds something lasting."
        case "Uranus": "is where you quietly refuse to be ordinary."
        case "Neptune": "softens the border between you and your imagination."
        case "Pluto": "works slowly, deep below the surface."
        default: "is one honest thread in your chart."
        }
    }

    private static func elementInsightPhrase(for element: String) -> String {
        switch element {
        case "Fire": "you move first and make sense of it on the way."
        case "Earth": "you trust what you can build, touch, and keep."
        case "Air": "you live through ideas, words, and connection."
        default: "you read the undercurrent before anyone speaks."
        }
    }
}
