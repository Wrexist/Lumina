@testable import Lumina
import XCTest

/// Guideline 2.3.1 is about the binary, not the store page: what the app
/// *says* it does has to match what it does. The pre-launch audit caught the
/// same drift three separate times — the name, the keywords, and then Help
/// copy still describing "on-device palm analysis" two articles above the FAQ
/// admitting palm reading isn't built. These tests make that class of drift a
/// build failure instead of a review rejection.
///
/// When palm reading actually ships, `.palm` joins `LuminaTab.visible` and
/// every assertion here flips by itself — nothing to remember to undo.
///
/// `@MainActor` on the class, not per-test: `GlossaryStore` is main-actor
/// isolated and `HelpView` inherits isolation from `View`, so every assertion
/// here touches main-actor state under Swift 6's strict checking.
@MainActor
final class ReleaseAccuracyTests: XCTestCase {
    private static let palmTerms = ["palm", "palmistry", "life line", "heart line", "head line"]

    private var palmIsReachable: Bool {
        LuminaTab.visible.contains(.palm)
    }

    /// The one article allowed to say the word is the one that says we don't
    /// do it — and it has to keep saying that.
    func testHelpCopyNeverClaimsAnUnshippedFeature() {
        guard !palmIsReachable else { return }

        for article in HelpView.allArticles where article.id != "palm-when" {
            let text = (article.title + " " + article.body).lowercased()
            for term in Self.palmTerms {
                XCTAssertFalse(
                    text.contains(term),
                    "Help article '\(article.id)' mentions \(term) while the Palm tab is unreachable"
                )
            }
        }
    }

    func testThePalmArticleStillSaysItIsNotBuilt() {
        guard !palmIsReachable else { return }

        let article = HelpView.allArticles.first { $0.id == "palm-when" }
        guard let article else {
            // Removing it is fine — silently rewording it into a claim is not.
            return
        }
        XCTAssertTrue(
            article.body.lowercased().contains("not yet"),
            "the palm FAQ must keep saying the feature isn't here"
        )
    }

    /// Definitions for "heart line" in an app with no palm surface advertise
    /// a feature the binary doesn't have. `GlossaryStore.shipped(_:)` filters
    /// them until the tab is real.
    func testGlossaryShipsNoTermsForUnreachableFeatures() {
        XCTAssertEqual(GlossaryStore.shipped(.palmistry), palmIsReachable)
        XCTAssertTrue(GlossaryStore.shipped(.astrology))
        XCTAssertTrue(GlossaryStore.shipped(.humanDesign))
        XCTAssertTrue(GlossaryStore.shipped(.general))
    }

    func testTheLoadedGlossaryContainsNoUnshippedCategories() throws {
        let store = GlossaryStore()
        store.loadIfNeeded(bundle: .main)
        guard !store.entries.isEmpty else {
            throw XCTSkip("Glossary.json not in the host bundle")
        }
        let shippable = store.entries.values.allSatisfy { GlossaryStore.shipped($0.category) }
        XCTAssertTrue(shippable, "a glossary entry survived for an unshipped feature")
    }

    /// The paywall may only list features that are actually gated, and each
    /// one has to carry its own copy — a blank or duplicated line means the
    /// list stopped describing what a subscriber actually receives.
    func testEveryPaidFeatureCarriesItsOwnCopy() {
        let features = PremiumFeature.allCases
        XCTAssertFalse(features.isEmpty, "a paywall selling nothing is a 3.1.2 rejection")

        for feature in features {
            XCTAssertFalse(feature.marketingLine.isEmpty, "\(feature.rawValue) has no paywall line")
            XCTAssertFalse(feature.lockedTitle.isEmpty, "\(feature.rawValue) has no locked title")
            XCTAssertFalse(feature.lockedBlurb.isEmpty, "\(feature.rawValue) has no locked blurb")
        }

        XCTAssertEqual(Set(features.map(\.marketingLine)).count, features.count)
        XCTAssertEqual(Set(features.map(\.lockedTitle)).count, features.count)
    }
}
