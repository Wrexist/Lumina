import SwiftData
import SwiftUI

/// Friend detail — compatibility headline, birth-info card, "remove
/// friend" with the standard `LuminaConfirmationDialog`.
struct FriendDetailView: View {
    let friend: Friend

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var confirmingRemove = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                header
                scoreCard
                birthInfoCard
                placeholderSynastry
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle(friend.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { trailingToolbar }
        .luminaConfirmation(
            "Remove \(friend.name)?",
            message: "This deletes them from your People tab. You can add them again any time.",
            confirmTitle: "Remove",
            isPresented: $confirmingRemove,
            onConfirm: handleRemove
        )
    }

    // MARK: - View building blocks

    private var header: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
            Text("REFLECTION ON")
                .font(LuminaTypography.mono)
                .tracking(1.4)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            Text(friend.name)
                .font(LuminaTypography.display)
        }
    }

    private var scoreCard: some View {
        let score = friend.compatibilityScore ?? compute()
        let label = CompatibilityScorer.Label(score: score)
        return LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(score)")
                        .font(.system(size: 56, weight: .light, design: .serif))
                        .foregroundStyle(LuminaColors.celestialBlue)
                    Text("/100")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                    Spacer()
                    LuminaBadge(title: label.displayName, tone: .neutral)
                }
                if let userBirth = UserBirthDataStore.userDefaults.load() {
                    Text(CompatibilityScorer.summary(for: userBirth.birthDate, friend.birthDate))
                        .font(LuminaTypography.body)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                } else {
                    Text("Add your birth info in Settings to score this match.")
                        .font(LuminaTypography.caption)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                }
            }
        }
    }

    private var birthInfoCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                row("Birth date", value: dateString(friend.birthDate))
                row("Birth time", value: friend.birthTime.map(timeString) ?? "Unknown")
                row("Birth place", value: friend.birthPlaceName ?? "Unknown")
                row("Source", value: friend.source.rawValue.capitalized)
            }
        }
    }

    private var placeholderSynastry: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                Text("Full synastry chart")
                    .font(LuminaTypography.heading)
                Text("The bi-wheel + 5-dimension narrative report ships with the backend `/synastry` endpoint in Phase 7. The score above is deterministic so you can already compare friends meaningfully.")
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
        }
    }

    @ToolbarContentBuilder
    private var trailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Remove", systemImage: "person.fill.xmark", role: .destructive) {
                    confirmingRemove = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("Friend options")
        }
    }

    // MARK: - Methods

    private func compute() -> Int {
        guard let userBirth = UserBirthDataStore.userDefaults.load() else { return 50 }
        let score = CompatibilityScorer.score(userBirth.birthDate, friend.birthDate)
        friend.compatibilityScore = score
        try? modelContext.save()
        return score
    }

    private func handleRemove() {
        modelContext.delete(friend)
        try? modelContext.save()
        dismiss()
    }

    private func row(_ key: String, value: String) -> some View {
        HStack {
            Text(key.uppercased())
                .font(LuminaTypography.mono)
                .tracking(1.2)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            Spacer()
            Text(value).font(LuminaTypography.body)
        }
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
