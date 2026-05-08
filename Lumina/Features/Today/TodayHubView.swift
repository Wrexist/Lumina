import SwiftUI

/// Phase-3 placeholder. Shipped layout in `ROADMAP.md` Phase 3.
/// Today's job: prove the shell works end-to-end — title, badge, primary
/// CTA, and one secondary surface — so the surrounding navigation can be
/// tested without the real reading pipeline.
struct TodayHubView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                header

                LuminaCard {
                    VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                        Text("Mercury squares Saturn — words feel heavier than usual.")
                            .font(LuminaTypography.heading)
                        Text("Tap below to read the full reflection.")
                            .font(LuminaTypography.bodyLight)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                    }
                }

                LuminaButton(title: "Read today", variant: .primary, systemImage: "book") {
                    // TODO(lumina): push DailyReadingView (Phase 3)
                }

                Divider()

                Text("WHAT'S HAPPENING")
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))

                ForEach(TodayPlaceholder.transits, id: \.self) { line in
                    HStack(alignment: .top, spacing: LuminaSpacing.sm) {
                        Text("•").font(LuminaTypography.body)
                        Text(line).font(LuminaTypography.body)
                    }
                }

                Divider()

                Text("QUICK ACTIONS")
                    .font(LuminaTypography.mono)
                    .tracking(1.4)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))

                quickActionsRow
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle("Today")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
            Text(TodayPlaceholder.dateLabel.uppercased())
                .font(LuminaTypography.mono)
                .tracking(1.4)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            Text("Your sky today")
                .font(LuminaTypography.display)
        }
    }

    private var quickActionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LuminaSpacing.md) {
                ForEach(TodayPlaceholder.quickActions, id: \.title) { action in
                    LuminaCard(padding: LuminaSpacing.md) {
                        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                            Image(systemName: action.systemImage)
                                .font(.system(size: 28, weight: .light))
                                .foregroundStyle(LuminaColors.celestialBlue)
                            Text(action.title).font(LuminaTypography.body)
                        }
                        .frame(width: 140, alignment: .leading)
                    }
                }
            }
        }
    }
}

private enum TodayPlaceholder {
    static let dateLabel = "Thursday · May 8"
    static let transits = [
        "Mercury □ Saturn (exact in 2 days)",
        "Moon enters Pisces",
        "Venus retrograde shadow ends",
    ]
    struct QuickAction { let title: String; let systemImage: String }
    static let quickActions: [QuickAction] = [
        .init(title: "Scan a palm", systemImage: "hand.raised"),
        .init(title: "Add a friend", systemImage: "person.2.badge.plus"),
        .init(title: "Reflect", systemImage: "moonphase.first.quarter"),
        .init(title: "See chart", systemImage: "circle.dotted"),
    ]
}

#Preview {
    NavigationStack {
        TodayHubView()
            .environment(GlossaryStore.shared)
    }
}
