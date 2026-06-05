import Foundation
#if canImport(Vision)
import Vision
#endif

/// Pure geometry: turns the key hand landmarks into `PalmFeatures`. Deliberately
/// free of Vision types so it's unit-testable with synthetic points; a thin
/// device-only Vision adapter (below) maps a real hand-pose observation onto it.
enum PalmFeatureExtractor {
    static func features(
        wrist: CGPoint,
        indexMCP: CGPoint,
        indexTip: CGPoint,
        middleMCP: CGPoint,
        middleTip: CGPoint,
        ringMCP: CGPoint,
        ringTip: CGPoint,
        littleMCP: CGPoint,
        littleTip: CGPoint
    ) -> PalmFeatures {
        let fingerLengths = [
            distance(indexMCP, indexTip),
            distance(middleMCP, middleTip),
            distance(ringMCP, ringTip),
            distance(littleMCP, littleTip),
        ]
        let average = fingerLengths.reduce(0, +) / Double(fingerLengths.count)
        return PalmFeatures(
            palmWidth: distance(indexMCP, littleMCP),
            palmLength: distance(wrist, middleMCP),
            averageFingerLength: average
        )
    }

    private static func distance(_ from: CGPoint, _ to: CGPoint) -> Double {
        let dx = Double(from.x - to.x)
        let dy = Double(from.y - to.y)
        return (dx * dx + dy * dy).squareRoot()
    }
}

#if canImport(Vision)
extension PalmFeatureExtractor {
    /// Device-only adapter: map a Vision hand-pose observation to `PalmFeatures`.
    /// Returns nil if any required joint is missing or below `minimumConfidence`
    /// — we'd rather decline a reading than fabricate one from noise.
    static func features(
        from observation: VNHumanHandPoseObservation,
        minimumConfidence: Float = 0.3
    ) -> PalmFeatures? {
        func point(_ joint: VNHumanHandPoseObservation.JointName) -> CGPoint? {
            guard let recognized = try? observation.recognizedPoint(joint),
                  recognized.confidence >= minimumConfidence else { return nil }
            return recognized.location
        }
        guard
            let wrist = point(.wrist),
            let indexMCP = point(.indexMCP), let indexTip = point(.indexTip),
            let middleMCP = point(.middleMCP), let middleTip = point(.middleTip),
            let ringMCP = point(.ringMCP), let ringTip = point(.ringTip),
            let littleMCP = point(.littleMCP), let littleTip = point(.littleTip)
        else { return nil }
        return features(
            wrist: wrist,
            indexMCP: indexMCP,
            indexTip: indexTip,
            middleMCP: middleMCP,
            middleTip: middleTip,
            ringMCP: ringMCP,
            ringTip: ringTip,
            littleMCP: littleMCP,
            littleTip: littleTip
        )
    }
}
#endif
