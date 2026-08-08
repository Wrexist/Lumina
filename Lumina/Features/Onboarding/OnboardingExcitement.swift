import SwiftUI

/// The rating moment, placed straight after the chart reveal — the one point
/// in onboarding where the user has just been shown something of their own.
///
/// Its own file rather than another case in `OnboardingScreens`: that enum is
/// at SwiftLint's type-body ceiling, same reason `WhatNext` moved out.
///
/// **Whatever they tap, Apple's sheet follows.** That is the whole design.
/// Guideline 1.1.7 rejects custom prompts that "manipulate customers into
/// leaving positive reviews", and showing the system sheet only for four and
/// five stars is the textbook case — it is also how a product ends up with a
/// rating that tells its own team nothing. So the stars ask how someone
/// feels, the screen says plainly what happens next, and the number never
/// gates anything.
extension OnboardingScreens {
    struct Excitement: View {
        /// Said before the tap, never discovered after it. A screen that
        /// springs the App Store card on someone reads as a trick the first
        /// time and is remembered as one — and "whatever you tapped" is the
        /// sentence that makes the no-filtering promise checkable by anyone
        /// who reads it, including a reviewer.
        /// `ReleaseAccuracyTests` fails the build if it stops saying so.
        static let ratingCardDisclosure = "Sending this also opens Apple's rating card, whatever you "
            + "tapped. You can dismiss it — and skipping this screen entirely is fine too."

        @Binding var rating: Int?
        /// What they told us to call them, on step three.
        let name: String

        private var greeting: String {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return "How excited are you to start your Lumina adventure?" }
            return "\(trimmed), how excited are you to start your Lumina adventure?"
        }

        var body: some View {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                    Text(greeting)
                        .font(LuminaTypography.heading)
                    Text("You've just met your chart. Tell us where you're starting from — "
                        + "it's the only way we find out whether the next release is better "
                        + "than this one.")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                }

                LuminaCard {
                    VStack(spacing: LuminaSpacing.md) {
                        LuminaStarRating(rating: $rating)
                            .frame(maxWidth: .infinity)
                        Text(scaleHint)
                            .font(LuminaTypography.caption)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }

                Text(Self.ratingCardDisclosure)
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            }
            .padding(.horizontal, LuminaSpacing.lg)
        }

        private var scaleHint: String {
            switch rating ?? 0 {
            case 1: "Not sold yet — that's useful to know."
            case 2: "Curious, with reservations."
            case 3: "Open to it."
            case 4: "Looking forward to this."
            case 5: "Genuinely excited — thank you."
            default: "1 star to 5. There's no wrong answer here."
            }
        }
    }
}
