import SwiftUI

/// Phase-9 placeholder. Renders today's prompt and the calendar entry
/// scaffolding so the navigation feels real before the actual journal
/// engine lands.
struct ReflectHubView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                Text("TODAY'S PROMPT")
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))

                LuminaCard {
                    VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                        Text("With Mercury squaring Saturn, where are your words asking to slow down?")
                            .font(LuminaTypography.heading)
                        Text("Write as little or as much as you want. Auto-saved, on this device only.")
                            .font(LuminaTypography.caption)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                    }
                }

                LuminaButton(title: "Write today's reflection", variant: .primary, systemImage: "pencil") {
                    // TODO(lumina): push JournalEntryView (Phase 9)
                }

                LuminaCard {
                    VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                        HStack(spacing: LuminaSpacing.sm) {
                            LuminaBadge(title: "Plus", tone: .premium)
                            Text("Pattern detection unlocks at 30 entries.")
                                .font(LuminaTypography.body)
                        }
                        Text("Once you've reflected for a month, Lumina Plus surfaces the emotional patterns connecting your entries.")
                            .font(LuminaTypography.bodyLight)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                    }
                }
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle("Reflect")
    }
}

#Preview {
    NavigationStack { ReflectHubView() }
}
