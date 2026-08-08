import SwiftUI

/// Five tappable stars.
///
/// Deliberately *not* a stand-in for Apple's rating sheet. It captures how
/// someone feels in a moment; it never decides whether the real sheet
/// appears. Guideline 1.1.7 rejects "custom review prompts that mimic or
/// replace the system rating and review prompts, or that manipulate
/// customers into leaving positive reviews" — surfacing Apple's sheet only
/// for the happy answers is precisely that, so nothing here reads the value
/// to make that decision (see `OnboardingScreens.Excitement`).
///
/// Each star is its own accessibility element rather than one adjustable
/// control: VoiceOver users get the same direct "three stars" tap everyone
/// else does, instead of having to swipe up four times.
struct LuminaStarRating: View {
    @Binding var rating: Int?
    var maximum = 5

    var body: some View {
        HStack(spacing: LuminaSpacing.sm) {
            ForEach(1...maximum, id: \.self) { value in
                star(value)
            }
        }
    }

    private func star(_ value: Int) -> some View {
        let isFilled = value <= (rating ?? 0)
        return Button {
            Haptics.light.play()
            rating = value
        } label: {
            Image(systemName: isFilled ? "star.fill" : "star")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(isFilled ? LuminaColors.goldInk : LuminaColors.inkBlack.opacity(0.35))
                // 52pt clears the 44pt minimum touch target with room, so a
                // thumb between two stars still lands where it looks like it
                // should.
                .frame(width: 52, height: 52)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(value == 1 ? "1 star" : "\(value) stars")
        .accessibilityAddTraits(rating == value ? [.isButton, .isSelected] : [.isButton])
    }
}
