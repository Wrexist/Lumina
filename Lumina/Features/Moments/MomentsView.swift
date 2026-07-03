import SwiftUI

/// Quiet timeline of the user's Moments — milestones they have actually
/// lived through. Unlocked moments first (newest on top, with their date);
/// what's still ahead sits below as dimmed rows with honest hints. No
/// percentages, no counters, no pressure — nothing here is waiting on the
/// user (brand: anti-streak, see `docs/NAVIGATION.md` §13).
struct MomentsView: View {
    @State private var moments = MomentsStore.shared
    @ScaledMetric private var iconCircleSize: CGFloat = 40

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.md) {
                intro
                unlockedSection
                stillAheadSection
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle("Moments")
    }

    // MARK: - Sections

    private var intro: some View {
        Text("A quiet record of what you've been here for. Nothing expires, and nothing is counting on you.")
            .font(LuminaTypography.bodyLight)
            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            .padding(.bottom, LuminaSpacing.sm)
    }

    @ViewBuilder
    private var unlockedSection: some View {
        let unlocked = moments.unlocked
        if unlocked.isEmpty {
            LuminaCard {
                Text("Your moments will gather here as they happen — no hurry.")
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
        } else {
            ForEach(unlocked, id: \.moment) { item in
                unlockedRow(item.moment, date: item.date)
            }
        }
    }

    @ViewBuilder
    private var stillAheadSection: some View {
        let locked = Moment.allCases.filter { !moments.isUnlocked($0) }
        if !locked.isEmpty {
            Text("STILL AHEAD")
                .font(LuminaTypography.mono)
                .tracking(1.4)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                .padding(.top, LuminaSpacing.sm)
            ForEach(locked, id: \.self) { moment in
                lockedRow(moment)
            }
        }
    }

    // MARK: - Rows

    private func unlockedRow(_ moment: Moment, date: Date) -> some View {
        LuminaCard {
            HStack(alignment: .top, spacing: LuminaSpacing.md) {
                iconCircle(moment.systemImage, unlocked: true)
                VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                    Text(moment.title)
                        .font(LuminaTypography.body)
                        .fontWeight(.medium)
                    Text(moment.subtitle)
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                    Text(date.formatted(date: .long, time: .omitted))
                        .font(LuminaTypography.caption)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// Locked rows deliberately hide the real title — "Still ahead" plus an
    /// honest hint, so the list invites rather than scores.
    private func lockedRow(_ moment: Moment) -> some View {
        LuminaCard {
            HStack(alignment: .top, spacing: LuminaSpacing.md) {
                iconCircle(moment.systemImage, unlocked: false)
                VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                    Text("Still ahead")
                        .font(LuminaTypography.body)
                    Text(moment.lockedHint)
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                }
            }
        }
        .opacity(0.55)
        .accessibilityElement(children: .combine)
    }

    private func iconCircle(_ systemImage: String, unlocked: Bool) -> some View {
        Image(systemName: systemImage)
            .font(LuminaTypography.body)
            .foregroundStyle(unlocked ? LuminaColors.mutedGold : LuminaColors.inkBlack.opacity(0.4))
            .frame(width: iconCircleSize, height: iconCircleSize)
            .background(
                Circle().fill(
                    unlocked
                        ? LuminaColors.mutedGold.opacity(0.16)
                        : LuminaColors.inkBlack.opacity(0.06)
                )
            )
            .accessibilityHidden(true)
    }
}

/// Small, calm card other surfaces embed exactly once when a moment is
/// newly unlocked (drive it with `MomentsStore.shared.latestUnseen` and call
/// `markSeen(_:)` alongside `onDismiss`). Static by design — no confetti,
/// no animation — so it is inherently reduce-motion safe.
struct MomentUnlockCard: View {
    let moment: Moment
    var onDismiss: () -> Void

    var body: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text("✦ A new moment — \(moment.title)")
                        .font(LuminaTypography.body)
                        .fontWeight(.medium)
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(LuminaTypography.caption)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.5))
                    }
                    .accessibilityLabel("Dismiss new moment card")
                }
                Text(moment.subtitle)
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                NavigationLink("See your moments") {
                    MomentsView()
                }
                .font(LuminaTypography.caption)
                .foregroundStyle(LuminaColors.celestialBlue)
            }
        }
    }
}

#Preview("Moments") {
    NavigationStack {
        MomentsView()
    }
}

#Preview("Unlock card") {
    NavigationStack {
        MomentUnlockCard(moment: .firstReflection) {}
            .padding(LuminaSpacing.lg)
            .background(LuminaColors.parchment)
    }
}
