import SwiftUI

/// Phase-7 + Phase-10 placeholder. Default state is empty until the user
/// adds at least one friend; once they do this becomes a sorted list.
struct PeopleHubView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: LuminaSpacing.lg) {
                LuminaEmptyState(
                    systemImage: "person.2",
                    title: "No one here yet",
                    body: "Add a friend, partner, or family member to see what's happening between you.",
                    primaryCTA: LuminaEmptyState.CTA(title: "Add someone", action: handleAdd),
                    secondaryCTA: LuminaEmptyState.CTA(title: "Scan a friend's QR", action: handleScan)
                )

                LuminaCard {
                    VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                        Text("Privacy")
                            .font(LuminaTypography.heading)
                        Text("If you import from contacts we only read names and birthdays — never phone numbers, addresses, or photos. Nothing leaves your device unless you explicitly share.")
                            .font(LuminaTypography.bodyLight)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                    }
                }
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle("People")
    }

    private func handleAdd() {
        // TODO(lumina): present add-friend sheet (Phase 10)
    }

    private func handleScan() {
        // TODO(lumina): present QR scanner (Phase 10)
    }
}

#Preview {
    NavigationStack { PeopleHubView() }
}
