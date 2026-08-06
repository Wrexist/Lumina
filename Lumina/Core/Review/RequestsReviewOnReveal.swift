import StoreKit
import SwiftUI

extension View {
    /// Asks for an App Store rating when the daily reading is unveiled on a
    /// new day — and only once `ReviewPrompt` says the app has earned it.
    ///
    /// Pass `DailyRevealState.lastRevealedDay`. That string changes exactly
    /// once per day the reading is actually uncovered, which is the signal the
    /// gate counts: a deliberate tap on a screen that loaded successfully.
    /// Nothing fires on the value merely being read back from storage at
    /// launch, because `onChange` doesn't run on first appearance.
    func requestsReviewOnReveal(day revealedDay: String?) -> some View {
        modifier(EarnedReviewRequest(revealedDay: revealedDay))
    }
}

/// The rating ask, as a modifier rather than inline in `TodayHubView`.
///
/// It lives here for two reasons. The `\.requestReview` action can only be
/// read from inside a view, so the call has to happen in one; and the next
/// earned moment worth asking on — a tenth reflection, a first synastry read
/// — should be able to reuse the gate and the delay instead of copying them.
private struct EarnedReviewRequest: ViewModifier {
    let revealedDay: String?

    @Environment(\.requestReview) private var requestReview

    func body(content: Content) -> some View {
        content.onChange(of: revealedDay) { _, newDay in
            // Only a real unveil counts. `nil` can only mean the record was
            // erased (account deletion), which is not engagement.
            guard newDay != nil else { return }
            recordAndAsk()
        }
    }

    private func recordAndAsk() {
        let prompt = ReviewPrompt.shared
        prompt.recordEngagement()
        guard prompt.isEligible else { return }
        Task {
            // Let the reveal animation finish first, so the system alert lands
            // over the reading the user just uncovered rather than over the
            // veil they tapped.
            try? await Task.sleep(for: .seconds(2))
            // Marked before the call, not after: `requestReview()` reports
            // nothing back — not whether it drew anything, not whether the
            // user had prompts switched off — so this is the only place the
            // once-per-version slot can be burned.
            prompt.markAsked()
            requestReview()
        }
    }
}
