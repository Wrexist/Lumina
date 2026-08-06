@testable import Lumina
import SwiftUI

// The card facsimiles and shared building blocks, in an extension so the main
// `TabPreviews` declaration stays under SwiftLint's 250-line type body. Split
// mechanically — nothing here changed when it moved.
extension TabPreviews {
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

    /// The **real** `RetrogradeCard`, driven by a fixed result, rather than a
    /// hand-built lookalike. The lookalike drifted the moment the shipped
    /// card gained its strip of retrograde planets — which is the failure
    /// mode of every reimplemented preview, and the reason this one now feeds
    /// the component its data instead of copying its markup.
    private static func retrogradeCard() -> some View {
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 14
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let station = calendar.date(from: components) ?? Self.sampleDate

        return RetrogradeCard(result: RetrogradesResult(
            calculatedAt: Self.sampleDate,
            at: Self.sampleDate,
            planets: [
                RetrogradeState(planet: "Mercury", isRetrograde: true,
                                nextStationAt: station, nextStationDirection: .direct),
                RetrogradeState(planet: "Saturn", isRetrograde: true,
                                nextStationAt: nil, nextStationDirection: nil),
                RetrogradeState(planet: "Venus", isRetrograde: false,
                                nextStationAt: nil, nextStationDirection: nil),
            ]
        ))
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

    private static func friendRow(name: String, score: Int, signs: String, label: String,
                                  sunSign: String) -> some View {
        LuminaCard(padding: LuminaSpacing.md) {
            HStack(spacing: LuminaSpacing.md) {
                // The shipped list draws the person's Sun-sign constellation
                // on a night-sky disc. A screenshot suite that skips it can't
                // catch a regression in the one surface those twelve assets
                // exist for.
                avatar(sunSign: sunSign)
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

    /// Mirrors `PeopleHubView.avatar(for:)` — midnight disc, gold rim, the
    /// real constellation art inset.
    private static func avatar(sunSign: String) -> some View {
        ZStack {
            Circle()
                .fill(LuminaColors.midnight)
                .overlay(Circle().stroke(LuminaColors.mutedGold.opacity(0.3), lineWidth: 1))
            if let constellation = LuminaImageAsset.constellation(sign: sunSign) {
                constellation.image
                    .resizable()
                    .scaledToFit()
                    .padding(LuminaSpacing.xs)
            }
        }
        .frame(width: 44, height: 44)
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
