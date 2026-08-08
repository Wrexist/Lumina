@testable import Lumina
import SwiftUI
import UIKit
import XCTest

/// Guards the WCAG AA contrast fix behind `LuminaColors.goldInk`. `mutedGold`
/// as text on `parchment` fails AA (~2:1), so gold *text* must use `goldInk`.
/// These assertions fail the merge if either token drifts back across the line.
final class GoldInkContrastTests: XCTestCase {
    private let minimumAA = 4.5

    func testGoldInkClearsAAAsTextOnParchment() {
        let ratio = Self.contrast(LuminaColors.goldInk, on: LuminaColors.parchment)
        XCTAssertGreaterThanOrEqual(ratio, minimumAA, "goldInk dropped below AA: \(ratio)")
    }

    func testMutedGoldStaysDecorativeOnly() {
        // Documents *why* goldInk exists: mutedGold is not a legible text color
        // on parchment, so it must stay reserved for fills/strokes/dots.
        let ratio = Self.contrast(LuminaColors.mutedGold, on: LuminaColors.parchment)
        XCTAssertLessThan(ratio, minimumAA, "mutedGold now passes AA — revisit goldInk")
    }

    /// Every defined centre in the bodygraph must be readable. Three of the
    /// four fills are light, so a single foreground can't serve them — this
    /// measures the actual pairing each centre ships.
    func testEveryDefinedCenterLabelClearsAAOnItsFill() {
        for center in HumanDesignCenter.allCases {
            let ratio = Self.contrast(center.definedLabelColor, on: center.fillColor)
            XCTAssertGreaterThanOrEqual(
                ratio, minimumAA,
                "\(center.displayName) label is \(String(format: "%.2f", ratio)):1 on its fill"
            )
        }
    }

    /// Documents the regression: `parchment` was the label colour for *every*
    /// defined centre, and it is unreadable on the two light fills. Guards
    /// against a well-meaning simplification putting it back.
    func testParchmentAloneWouldFailOnTheLightFills() {
        var lightFills = 0
        for center in HumanDesignCenter.allCases {
            guard Self.contrast(LuminaColors.parchment, on: center.fillColor) < minimumAA else { continue }
            lightFills += 1
            XCTAssertGreaterThanOrEqual(
                Self.contrast(LuminaColors.inkBlack, on: center.fillColor), minimumAA,
                "\(center.displayName) has no legible label colour in the palette at all"
            )
        }
        XCTAssertGreaterThan(lightFills, 0, "no fill needs ink any more — the mapping can be simplified")
    }

    // MARK: - WCAG helpers

    private static func contrast(_ foreground: Color, on background: Color) -> Double {
        let high = max(luminance(foreground), luminance(background))
        let low = min(luminance(foreground), luminance(background))
        return (high + 0.05) / (low + 0.05)
    }

    private static func luminance(_ color: Color) -> Double {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
    }

    private static func channel(_ value: CGFloat) -> Double {
        let component = Double(value)
        return component <= 0.03928 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
    }
}
