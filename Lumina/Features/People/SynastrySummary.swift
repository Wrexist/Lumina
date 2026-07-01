import Foundation

/// A one-line "here's your dynamic" read of a relationship, derived from the
/// real synastry cross-aspects — the deterministic core of the compatibility
/// report that competitors gate behind a paywall (see
/// `docs/COMPETITIVE-ANALYSIS.md`). It classifies the contact mix — flow vs
/// friction vs intensity — into a plain-language verdict specific to the two
/// actual charts, never a generic blurb.
enum SynastrySummary {
    /// A short headline describing the overall dynamic between two charts.
    static func headline(for aspects: [SynastryAspect]) -> String {
        let harmonious = aspects.filter { $0.type == .trine || $0.type == .sextile }.count
        let challenging = aspects.filter { $0.type == .square || $0.type == .opposition }.count
        let intense = aspects.filter { $0.type == .conjunction }.count

        if harmonious + challenging + intense == 0 {
            return "An unusually independent pairing — your charts barely interact."
        }
        if intense > harmonious && intense > challenging {
            return "Deeply intertwined — your charts blend in powerful, hard-to-ignore ways."
        }
        if harmonious > 0 && harmonious >= challenging * 2 {
            return "More flow than friction — an easy, supportive connection."
        }
        if challenging > 0 && challenging >= harmonious * 2 {
            return "A charged, growth-driven match — real spark, and real edges to work through."
        }
        return "A rich mix of ease and tension — comfortable, but rarely dull."
    }
}
