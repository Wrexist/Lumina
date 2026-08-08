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
        // Pinned to the constant, not a literal: the address moved once
        // already (lumina.app never existed, so every mail to it bounced) and
        // a hardcoded copy here would have gone stale silently.
        XCTAssertEqual(components.path, FeedbackMail.address)
        XCTAssertTrue(FeedbackMail.address.contains("@"), "feedback address must be a real mailbox")
        XCTAssertFalse(FeedbackMail.address.hasSuffix("@lumina.app"), "lumina.app does not exist yet")
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

    // MARK: - PaywallCopy
    //
    // These replace two tests that asserted the *old* behaviour: a hardcoded
    // "$59.99" and a "$41.99" rescue price. That rescue price was never
    // charged — the view purchased the standard annual package — so the tests
    // were pinning a Guideline 3.1.2 violation in place. What follows pins
    // the invariant that replaced it: a price reaches the screen only by
    // being read off a real `PlanOffer`.

    private func offer(
        _ plan: IAPManager.PremiumPlan,
        _ price: String,
        intro: String? = nil
    ) -> IAPManager.PlanOffer {
        IAPManager.PlanOffer(plan: plan, localizedPrice: price, introductoryOffer: intro)
    }

    func testPlanTitleQuotesTheStorefrontPriceVerbatim() {
        // A non-USD, comma-decimal storefront: the string must survive
        // untouched. Any reformatting here would be a price we don't charge.
        XCTAssertEqual(planTitleFor(offer(.annual, "59,99 €")), "59,99 € / year")
        XCTAssertEqual(planTitleFor(offer(.monthly, "¥1,500")), "¥1,500 / month")
    }

    func testPrimaryCTAQuotesNoPriceWhenNoOfferResolved() {
        // RevenueCat unconfigured, offering not live, or the network is down.
        let title = PaywallCopy.primaryCTATitle(for: .annual, in: [])
        XCTAssertEqual(title, "Continue")
        XCTAssertFalse(title.contains("$"))
    }

    func testPrimaryCTAUsesTheSelectedPlanNotTheFirstOne() {
        // The old view substituted the annual package for whatever was
        // selected, charging a price the user was never shown.
        let offers = [offer(.annual, "$59.99"), offer(.monthly, "$9.99")]
        XCTAssertEqual(
            PaywallCopy.primaryCTATitle(for: .monthly, in: offers),
            "Subscribe — $9.99"
        )
    }

    func testPrimaryCTAPromisesATrialOnlyWhenTheProductCarriesOne() {
        let withTrial = [offer(.annual, "$59.99", intro: "7 days free")]
        XCTAssertEqual(
            PaywallCopy.primaryCTATitle(for: .annual, in: withTrial),
            "Start your 7 days free"
        )
        let withoutTrial = [offer(.annual, "$59.99")]
        XCTAssertFalse(
            PaywallCopy.primaryCTATitle(for: .annual, in: withoutTrial)
                .localizedCaseInsensitiveContains("free")
        )
    }

    func testRescueCopyNeverImpliesADiscount() {
        for variant in [PaywallOfferView.Variant.initial, .rescue] {
            let copy = PaywallCopy.trustCopy(for: variant)
            XCTAssertFalse(copy.contains("%"), "\(variant) copy implies a discount")
            XCTAssertFalse(copy.contains("$"), "\(variant) copy hardcodes a price")
            XCTAssertTrue(copy.contains("Cancel anytime"), "\(variant) copy must keep the cancel promise")
        }
        XCTAssertTrue(PaywallCopy.trustCopy(for: .rescue).hasPrefix("This is the last time"))
    }

    private func planTitleFor(_ offer: IAPManager.PlanOffer) -> String {
        PaywallCopy.planTitle(offer)
    }
}
