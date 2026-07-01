import Foundation

/// Turns a `SynastryAspect` into a short, plain one-liner for the People tab:
/// "Your Venus conjunct their Mars". No invented imagery — just the real
/// contact between the two charts, in the brand's editorial voice. Shares the
/// aspect vocabulary with `TransitPhrasing`.
enum SynastryPhrasing {
    /// "Your <planetA> <aspect> their <planetB>".
    static func sentence(for aspect: SynastryAspect) -> String {
        "Your \(aspect.planetA) \(TransitPhrasing.aspectWord(aspect.type)) their \(aspect.planetB)"
    }
}
