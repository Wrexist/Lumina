import CoreLocation
import Foundation
import MapKit
import OSLog

/// MapKit-backed autocomplete for the birth-place onboarding step.
/// Wraps `MKLocalSearchCompleter`'s delegate-based API behind an
/// `@Observable` class so the SwiftUI view can bind directly to results.
///
/// On airplane mode or when MapKit can't reach Apple's geocoder we fall
/// through to a manual entry path (Phase-2 onboarding promises an offline
/// fallback per `docs/NAVIGATION.md` §6).
@MainActor
@Observable
final class BirthPlaceSearch: NSObject {
    struct Suggestion: Identifiable, Hashable, Sendable {
        let title: String
        let subtitle: String
        var id: String { "\(title)|\(subtitle)" }
    }

    struct Resolved: Hashable, Sendable {
        let displayName: String
        let latitude: Double
        let longitude: Double
        let timeZoneIdentifier: String
    }

    private let logger = Logger(subsystem: "app.lumina.ios", category: "BirthPlaceSearch")
    private let completer: MKLocalSearchCompleter

    private(set) var query = ""
    private(set) var suggestions: [Suggestion] = []
    private(set) var lastError: LuminaError?

    override init() {
        let completer = MKLocalSearchCompleter()
        completer.resultTypes = .address
        self.completer = completer
        super.init()
        completer.delegate = self
    }

    /// Updates the live-search query string. The MapKit completer
    /// internally debounces — we don't add another layer.
    func update(query: String) {
        self.query = query
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            suggestions = []
            return
        }
        completer.queryFragment = query
    }

    /// Resolve a tapped suggestion to coordinates + IANA time zone.
    func resolve(_ suggestion: Suggestion) async throws -> Resolved {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(suggestion.title), \(suggestion.subtitle)"
        let search = MKLocalSearch(request: request)
        let response: MKLocalSearch.Response
        do {
            response = try await search.start()
        } catch {
            throw LuminaError.from(error)
        }
        guard let item = response.mapItems.first else {
            throw LuminaError.unknown(underlyingMessage: "Couldn't find that place — try a nearby city.")
        }
        // iOS 26 deprecated `placemark`; `location` is the non-optional CLLocation replacement.
        let coordinate = item.location.coordinate
        // `MKMapItem.timeZone` is optional and is NOT always populated. This
        // used to fall back to UTC silently, so a Los Angeles birth could be
        // computed 8 hours off — wrong Ascendant, wrong houses, and a Moon
        // that can land in the wrong sign — with nothing to tell the user.
        // The bad zone was then persisted into `BirthData` and reused for
        // every chart, share payload and comparison from then on.
        //
        // For an app whose whole pitch is "we compute this properly", a
        // silent 8-hour error is the worst possible failure. Treat an
        // unresolved zone as an unresolved PLACE: the caller surfaces the
        // manual sheet, which has a validated time-zone picker.
        guard let timeZone = item.timeZone else {
            throw LuminaError.unknown(
                underlyingMessage: "We couldn't work out the time zone for that place. "
                    + "Pick it manually so your chart is accurate."
            )
        }
        return Resolved(
            displayName: "\(suggestion.title), \(suggestion.subtitle)",
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            timeZoneIdentifier: timeZone.identifier
        )
    }
}

extension BirthPlaceSearch: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let mapped = completer.results.map { Suggestion(title: $0.title, subtitle: $0.subtitle) }
        Task { @MainActor in
            self.suggestions = mapped
            self.lastError = nil
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        Task { @MainActor in
            self.logger.error("birth-place autocomplete failed: \(error.localizedDescription)")
            self.lastError = LuminaError.from(error)
            self.suggestions = []
        }
    }
}
