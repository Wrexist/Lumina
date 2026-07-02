@testable import Lumina
import XCTest

/// Regression tests for the 2026-07 fix batch: People list sorting,
/// per-friend share filenames, the honest feedback `mailto:` flow, and the
/// paywall's single-source fallback price copy.
@MainActor
final class FeatureFixTests: XCTestCase {
    // MARK: - FriendSortOrder

    private func makeFriend(_ name: String, score: Int? = nil, addedDaysAgo: Double = 0) -> Friend {
        Friend(
            name: name,
            birthDate: Date(timeIntervalSince1970: 0),
            compatibilityScore: score,
            createdAt: Date(timeIntervalSinceNow: -addedDaysAgo * 86_400)
        )
    }

    func testRawValuesAreStableForAppStoragePersistence() {
        // These strings are persisted in UserDefaults ("peopleSortOrder");
        // renaming a case must not silently reset users to the default.
        XCTAssertEqual(FriendSortOrder.recentlyAdded.rawValue, "recentlyAdded")
        XCTAssertEqual(FriendSortOrder.name.rawValue, "name")
        XCTAssertEqual(FriendSortOrder.compatibility.rawValue, "compatibility")
    }

    func testRecentlyAddedSortsNewestFirst() {
        let friends = [
            makeFriend("Old", addedDaysAgo: 10),
            makeFriend("New", addedDaysAgo: 0),
            makeFriend("Middle", addedDaysAgo: 5),
        ]
        let sorted = FriendSortOrder.recentlyAdded.sorted(friends).map(\.name)
        XCTAssertEqual(sorted, ["New", "Middle", "Old"])
    }

    func testNameSortIsCaseInsensitiveAscending() {
        let friends = [makeFriend("zoe"), makeFriend("Amir"), makeFriend("mara")]
        let sorted = FriendSortOrder.name.sorted(friends).map(\.name)
        XCTAssertEqual(sorted, ["Amir", "mara", "zoe"])
    }

    func testCompatibilitySortsHighestFirstWithNilLast() {
        let friends = [
            makeFriend("NoScore", score: nil, addedDaysAgo: 3),
            makeFriend("Low", score: 20, addedDaysAgo: 2),
            makeFriend("High", score: 90, addedDaysAgo: 1),
        ]
        let sorted = FriendSortOrder.compatibility.sorted(friends).map(\.name)
        XCTAssertEqual(sorted, ["High", "Low", "NoScore"])
    }

    func testCompatibilityNilScoresFallBackToNewestFirst() {
        let friends = [
            makeFriend("OlderNoScore", score: nil, addedDaysAgo: 8),
            makeFriend("NewerNoScore", score: nil, addedDaysAgo: 1),
            makeFriend("Scored", score: 1, addedDaysAgo: 0),
        ]
        let sorted = FriendSortOrder.compatibility.sorted(friends).map(\.name)
        XCTAssertEqual(sorted, ["Scored", "NewerNoScore", "OlderNoScore"])
    }

    // MARK: - CompatibilityShareButton filenames

    func testShareFileNameIsKeyedByFriend() {
        let anna = CompatibilityShareButton.shareFileName(for: "Anna")
        let ben = CompatibilityShareButton.shareFileName(for: "Ben")
        XCTAssertNotEqual(anna, ben, "one fixed filename let friend A's sheet share friend B's card")
        XCTAssertTrue(anna.hasSuffix(".png"))
        XCTAssertTrue(anna.hasPrefix("lumina-compatibility-"))
    }

    func testShareFileNameIsDeterministicAndFilesystemSafe() {
        let first = CompatibilityShareButton.shareFileName(for: "Dr. Strange Löve!")
        let second = CompatibilityShareButton.shareFileName(for: "Dr. Strange Löve!")
        XCTAssertEqual(first, second)
        XCTAssertFalse(first.contains(" "))
        XCTAssertFalse(first.contains("!"))
        XCTAssertFalse(first.contains("/"))
    }

    func testShareFileNameHashDisambiguatesSlugCollisions() {
        // Both slugify to "anna-b"; the appended name hash must keep the
        // temp files distinct.
        let spaced = CompatibilityShareButton.shareFileName(for: "Anna B")
        let dashed = CompatibilityShareButton.shareFileName(for: "Anna-B")
        XCTAssertNotEqual(spaced, dashed)
    }

    // MARK: - FeedbackMail

    func testMailtoURLTargetsFeedbackAddressWithSubjectAndBody() throws {
        let url = try XCTUnwrap(FeedbackMail.mailtoURL(subject: "A thought", message: "Love the app"))
        XCTAssertEqual(url.scheme, "mailto")
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.path, "feedback@lumina.app")
        XCTAssertEqual(components.queryItems?.first { $0.name == "subject" }?.value, "A thought")
        XCTAssertEqual(components.queryItems?.first { $0.name == "body" }?.value, "Love the app")
    }

    func testMailtoURLOmitsBlankSubjectAndRoundTripsMultilineBody() throws {
        let body = "line one\nline two — and more"
        let url = try XCTUnwrap(FeedbackMail.mailtoURL(subject: "   ", message: body))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertNil(components.queryItems?.first { $0.name == "subject" })
        XCTAssertEqual(components.queryItems?.first { $0.name == "body" }?.value, body)
    }

    // MARK: - PaywallOfferView.PriceDisplay

    func testPaywallFallbackPricesMatchVariant() {
        let initial = PaywallOfferView.PriceDisplay.fallback(for: .initial)
        let rescue = PaywallOfferView.PriceDisplay.fallback(for: .rescue)
        XCTAssertEqual(initial.yearlyPrice, "$59.99")
        XCTAssertEqual(rescue.yearlyPrice, "$41.99")
    }

    func testPaywallFallbackDisclosesUSDReferencePricing() {
        // The fallback must never masquerade as a localized price — the copy
        // has to say the shown figure is the USD reference.
        for variant in [PaywallOfferView.Variant.initial, .rescue] {
            let display = PaywallOfferView.PriceDisplay.fallback(for: variant)
            XCTAssertTrue(display.disclosure.contains("USD"))
        }
    }
}
