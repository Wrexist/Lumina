import Foundation
#if canImport(Vision)
import Vision
#endif

/// The nine hand landmarks the geometry needs, in one shared coordinate space.
/// Grouping them keeps `PalmFeatureExtractor.features` to a single parameter
/// (and well under the function-parameter-count budget).
struct HandLandmarks: Equatable, Sendable {
    let wrist: CGPoint
    let indexMCP: CGPoint
    let indexTip: CGPoint
    let middleMCP: CGPoint
    let middleTip: CGPoint
    let ringMCP: CGPoint
    let ringTip: CGPoint
    let littleMCP: CGPoint
    let littleTip: CGPoint
}

extension HandLandmarks {
    /// Vision normalizes each axis independently — x by image *width*, y by
    /// image *height* — so Euclidean distances between raw normalized points
    /// mix units on any non-square image (a square palm on a 4:3 capture reads
    /// as a long one). Rescaling into pixel space restores a single uniform
    /// coordinate space before any distance is measured.
    func rescaled(to imageSize: CGSize) -> HandLandmarks {
        func pixel(_ point: CGPoint) -> CGPoint {
            CGPoint(x: point.x * imageSize.width, y: point.y * imageSize.height)
        }
        return HandLandmarks(
            wrist: pixel(wrist),
            indexMCP: pixel(indexMCP),
            indexTip: pixel(indexTip),
            middleMCP: pixel(middleMCP),
            middleTip: pixel(middleTip),
            ringMCP: pixel(ringMCP),
            ringTip: pixel(ringTip),
            littleMCP: pixel(littleMCP),
            littleTip: pixel(littleTip)
        )
    }
}

/// Pure geometry: turns the key hand landmarks into `PalmFeatures`. Deliberately
/// free of Vision types so it's unit-testable with synthetic points; a thin
/// device-only Vision adapter (below) maps a real hand-pose observation onto it.
enum PalmFeatureExtractor {
    static func features(from landmarks: HandLandmarks) -> PalmFeatures {
        let fingerLengths = [
            distance(landmarks.indexMCP, landmarks.indexTip),
            distance(landmarks.middleMCP, landmarks.middleTip),
            distance(landmarks.ringMCP, landmarks.ringTip),
            distance(landmarks.littleMCP, landmarks.littleTip),
        ]
        let average = fingerLengths.reduce(0, +) / Double(fingerLengths.count)
        return PalmFeatures(
            palmWidth: distance(landmarks.indexMCP, landmarks.littleMCP),
            palmLength: distance(landmarks.wrist, landmarks.middleMCP),
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
    /// `imageSize` is the pixel size of the analyzed image; it rescales the
    /// per-axis normalized joints into one uniform space (see
    /// `HandLandmarks.rescaled(to:)`), without which every proportion is
    /// skewed by the image's aspect ratio.
    static func features(
        from observation: VNHumanHandPoseObservation,
        imageSize: CGSize,
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
        return features(from: HandLandmarks(
            wrist: wrist,
            indexMCP: indexMCP,
            indexTip: indexTip,
            middleMCP: middleMCP,
            middleTip: middleTip,
            ringMCP: ringMCP,
            ringTip: ringTip,
            littleMCP: littleMCP,
            littleTip: littleTip
        ).rescaled(to: imageSize))
    }
}
#endif
