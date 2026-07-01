import SwiftUI
import WidgetKit

/// The widget extension's entry point. A `WidgetBundle` lets us add more
/// widgets later (transits, moon phase) without a second target — for now it
/// vends the single Cosmic Signature widget.
@main
struct LuminaWidgetBundle: WidgetBundle {
    var body: some Widget {
        CosmicWidget()
    }
}
