@testable import Lumina
import SwiftUI

/// Full-tab compositions for screenshots. The real hub views load
/// asynchronously (which `ImageRenderer` can't drive) and depend on SwiftData
/// / environment, so these reassemble each tab from the *real* components
/// (BigThreeBand, ChartWheelView, AskYourChartCard, StrongestAspectsCard, the
/// daily reading, …) with sample data — a faithful render of what each tab
/// shows. Each returns a left-aligned `VStack` (no `ScrollView`, which
/// `ImageRenderer` can't size); the renderer fixes the width + background.
enum TabPreviews {
    /// Fixed date so the Today hero renders identically across runs — a real
    /// Tuesday (2026-06-02), so the kicker reads "TUESDAY · JUN 2".
    static let sampleDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 2
        return Calendar(identifier: .gregorian).date(from: components) ?? Date(timeIntervalSince1970: 0)
    }()

    static func chart(_ chart: NatalChart) -> some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
            Text("Chart").font(LuminaTypography.display)
            BigThreeBand(chart: chart)
            AskYourChartCard(chart: chart)
            ChartWheelView(chart: chart)
            AspectLegend()
            StrongestAspectsCard(chart: chart)
        }
        .padding(LuminaSpacing.lg)
    }

    static func today(chart: NatalChart, headline: String?, secondary: [String], reading: String) -> some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
            // The real immersive Today hero (static frame — no gyroscope in
            // the ImageRenderer screenshot harness) so the render reflects
            // what ships in `TodayHubView`.
            CelestialHeroCard(date: Self.sampleDate, showsMotion: false)
            BigThreeBand(chart: chart)
            LuminaCard {
                VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                    Text(headline ?? "A quiet sky today.")
                        .font(LuminaTypography.heading)
                    Text("Tap any planet on the Chart tab to learn more about your placements.")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                }
            }
            LuminaCard {
                VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                    HStack {
                        Text("Your reading").font(LuminaTypography.heading)
                        Spacer()
                        LuminaBadge(title: "Audio soon", tone: .neutral)
                    }
                    Text(reading)
                        .font(LuminaTypography.body)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            moonCard()
            retrogradeCard()
            chapterCard()
            bulletSection(title: "WHAT'S HAPPENING", lines: secondary)
        }
        .padding(LuminaSpacing.lg)
    }

    static func people() -> some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
            Text("People").font(LuminaTypography.display)
            friendRow(name: "Sam", score: 73, signs: "Gemini · Leo", label: "Harmonious")
            friendRow(name: "Alex", score: 58, signs: "Virgo · Pisces", label: "Stimulating")
            friendRow(name: "Mia", score: 84, signs: "Libra · Aquarius", label: "Magnetic")
            LuminaCard(surface: .glass) {
                VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                    HStack(spacing: LuminaSpacing.sm) {
                        Image(systemName: "lock").foregroundStyle(LuminaColors.celestialBlue)
                        Text("Privacy").font(LuminaTypography.heading)
                    }
                    Text("Friends live on this device only. We never sync names or birthdays to a server.")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                }
            }
        }
        .padding(LuminaSpacing.lg)
    }

    static func reflect() -> some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
            Text("Reflect").font(LuminaTypography.display)
            LuminaCard(surface: .glass) {
                VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                    kickerLabel("TODAY'S PROMPT")
                    Text("Where in your life are you being asked to slow down and revise rather than push?")
                        .font(LuminaTypography.heading)
                }
            }
            entryRow(date: "Tuesday · Jun 3", excerpt: "Felt a real shift after the conversation this morning…")
            entryRow(date: "Sunday · Jun 1", excerpt: "Quiet day. Noticed I keep circling the same worry.")
        }
        .padding(LuminaSpacing.lg)
    }

    static func palm() -> some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
            Text("Palm").font(LuminaTypography.display)
            infoCard(
                icon: "wand.and.sparkles",
                title: "Why ours is different",
                body: "Every other app overlays a generic illustration and writes a generic reading. Lumina actually traces your lines with an on-device model trained on real palm images.",
                badge: nil
            )
            LuminaCard {
                VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                    HStack(spacing: LuminaSpacing.sm) {
                        LuminaBadge(title: "Plus", tone: .premium)
                        Text("Unlimited scans").font(LuminaTypography.body)
                    }
                    Text("Free includes one scan a month. Lumina Plus removes the limit.")
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                }
            }
            infoCard(
                icon: nil,
                title: "Where we are",
                body: "Palm scanning is coming soon. We're making sure the on-device line tracing works fairly across every skin tone before we ship it.",
                badge: "Soon"
            )
        }
        .padding(LuminaSpacing.lg)
    }

    // MARK: - Today cards (facsimiles of the real self-loading cards)

    private static func moonCard() -> some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                kickerLabel("TONIGHT'S MOON")
                HStack(spacing: LuminaSpacing.md) {
                    Image(systemName: "moonphase.waning.gibbous")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(LuminaColors.mutedGold)
                    VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                        Text("Waning Gibbous").font(LuminaTypography.heading)
                        Text("78% illuminated")
                            .font(LuminaTypography.body)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                        Text("New moon in 9 days")
                            .font(LuminaTypography.caption)
                            .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                    }
                }
            }
        }
    }

    private static func retrogradeCard() -> some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                kickerLabel("RETROGRADES")
                Text("Mercury is retrograde right now.")
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
                HStack(alignment: .top, spacing: LuminaSpacing.sm) {
                    Text("•").font(LuminaTypography.caption)
                    Text("Mercury turns direct Jun 14")
                        .font(LuminaTypography.caption)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                }
            }
        }
    }

    private static func chapterCard() -> some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                kickerLabel("YOUR CURRENT CHAPTER")
                Text("Your progressed Moon is in Scorpio — the emotional season you're moving through now.")
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Shared building blocks

    private static func kickerLabel(_ text: String) -> some View {
        Text(text)
            .font(LuminaTypography.mono)
            .tracking(1.4)
            .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
    }

    private static func sectionHeader(kicker: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
            kickerLabel(kicker)
            Text(title).font(LuminaTypography.display)
        }
    }

    private static func bulletSection(title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
            kickerLabel(title)
            ForEach(lines, id: \.self) { line in
                HStack(alignment: .top, spacing: LuminaSpacing.sm) {
                    Text("•").font(LuminaTypography.body)
                    Text(line).font(LuminaTypography.body)
                }
            }
        }
    }

    private static func friendRow(name: String, score: Int, signs: String, label: String) -> some View {
        LuminaCard(padding: LuminaSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                    Text(name).font(LuminaTypography.heading)
                    Text(signs)
                        .font(LuminaTypography.bodyLight)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: LuminaSpacing.xs) {
                    Text("\(score)")
                        .font(.system(size: 28, weight: .light, design: .serif))
                        .foregroundStyle(LuminaColors.celestialBlue)
                    LuminaBadge(title: label, tone: .neutral)
                }
            }
        }
    }

    private static func entryRow(date: String, excerpt: String) -> some View {
        LuminaCard(padding: LuminaSpacing.md) {
            VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                Text(date)
                    .font(LuminaTypography.mono)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                Text(excerpt)
                    .font(LuminaTypography.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private static func infoCard(icon: String?, title: String, body: String, badge: String?) -> some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                HStack(spacing: LuminaSpacing.sm) {
                    if let badge {
                        LuminaBadge(title: badge, tone: .neutral)
                    }
                    if let icon {
                        Image(systemName: icon).foregroundStyle(LuminaColors.celestialBlue)
                    }
                    Text(title).font(LuminaTypography.heading)
                }
                Text(body)
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
