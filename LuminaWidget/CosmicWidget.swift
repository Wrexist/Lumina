import SwiftUI
import WidgetKit

/// Layout constants for the widget. `LuminaSpacing` lives in the app target, so
/// the extension carries its own small set (kept in sync by eye — the widget
/// has a fixed, simple layout that rarely changes).
private enum WidgetMetric {
    static let stackSpacing: CGFloat = 8
    static let rowSpacing: CGFloat = 8
    static let labelWidth: CGFloat = 58
    static let wordmarkTracking: CGFloat = 3
}

/// One rendered moment of the user's cosmic signature. `snapshot` is nil until
/// the app has published one (fresh install, or a dev build without the App
/// Group provisioned) — the view falls back to an invitation in that case.
struct CosmicEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

/// Feeds the widget its timeline. There's nothing time-varying to schedule —
/// the signature only changes when the user's chart does, at which point the
/// app calls `WidgetCenter.reloadAllTimelines()` — so we publish a single entry
/// and never expire it.
struct CosmicProvider: TimelineProvider {
    func placeholder(in context: Context) -> CosmicEntry {
        CosmicEntry(date: .now, snapshot: WidgetSharedStore.read())
    }

    func getSnapshot(in context: Context, completion: @escaping (CosmicEntry) -> Void) {
        completion(CosmicEntry(date: .now, snapshot: WidgetSharedStore.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CosmicEntry>) -> Void) {
        let entry = CosmicEntry(date: .now, snapshot: WidgetSharedStore.read())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

/// The Cosmic Signature widget — the user's Big-3 on their home screen. Small
/// and medium families; a static (non-configurable) widget for v1.
struct CosmicWidget: Widget {
    let kind = "CosmicWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CosmicProvider()) { entry in
            CosmicWidgetView(entry: entry)
                // Without this, tapping the widget only cold-launched the app
                // on whatever tab was last used — losing the one deep-link
                // affordance this retention feature has. `lumina://chart` is
                // registered in project.yml's CFBundleURLSchemes and handled
                // by `LuminaDeepLink`.
                .widgetURL(URL(string: "lumina://chart"))
        }
        .configurationDisplayName("Cosmic Signature")
        .description("Your Sun, Moon, and Rising — always on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// A premium midnight card. Colours are declared with `Color(red:green:blue:)`
/// because `LuminaColors` (and its `Color(hex:)` helper) live in the app
/// target, not this extension — the values mirror the brand palette.
struct CosmicWidgetView: View {
    let entry: CosmicEntry

    private var midnight: Color { Color(red: 0.043, green: 0.078, blue: 0.216) }
    private var parchment: Color { Color(red: 0.961, green: 0.941, blue: 0.902) }
    private var gold: Color { Color(red: 0.788, green: 0.663, blue: 0.431) }

    var body: some View {
        VStack(alignment: .leading, spacing: WidgetMetric.stackSpacing) {
            Text("LUMINA")
                .font(.system(.caption2, design: .monospaced))
                .tracking(WidgetMetric.wordmarkTracking)
                .foregroundStyle(gold)
            Spacer()
            content
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(midnight, for: .widget)
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = entry.snapshot, snapshot.hasSigns {
            VStack(alignment: .leading, spacing: WidgetMetric.rowSpacing) {
                signRow(label: "SUN", value: snapshot.sunSign)
                signRow(label: "MOON", value: snapshot.moonSign)
                signRow(label: "RISING", value: snapshot.risingSign)
            }
        } else {
            Text("Open Lumina to reveal your chart.")
                .font(.system(.footnote, design: .serif))
                .foregroundStyle(parchment)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func signRow(label: String, value: String?) -> some View {
        if let value {
            HStack(spacing: WidgetMetric.rowSpacing) {
                Text(label)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(gold.opacity(0.85))
                    .frame(width: WidgetMetric.labelWidth, alignment: .leading)
                Text(value)
                    .font(.system(.title3, design: .serif))
                    .foregroundStyle(parchment)
            }
        }
    }
}
