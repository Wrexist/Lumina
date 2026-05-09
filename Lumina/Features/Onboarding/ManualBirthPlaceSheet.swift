import SwiftUI

/// Offline / no-results fallback for the birth-place step. The user enters
/// latitude, longitude, and picks a time zone manually — useful in airplane
/// mode, on a flaky cellular network, or for historical / obscure
/// localities MapKit can't resolve.
///
/// Validation: latitude in [-90, 90], longitude in [-180, 180], time zone
/// must be a real IANA identifier. On Save we feed
/// `OnboardingState.applyResolvedPlace(...)` exactly the same way the
/// MapKit path does so the rest of onboarding doesn't branch.
struct ManualBirthPlaceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var state: OnboardingState

    @State private var name = ""
    @State private var latitudeText = ""
    @State private var longitudeText = ""
    @State private var timeZoneIdentifier = TimeZone.current.identifier
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                    blurb
                    nameField
                    coordinateRow
                    timeZonePicker
                    if let error {
                        Text(error)
                            .font(LuminaTypography.caption)
                            .foregroundStyle(LuminaColors.blush)
                    }
                    LuminaButton(title: "Save", variant: .primary, isEnabled: validated != nil) {
                        save()
                    }
                    Spacer()
                }
                .padding(LuminaSpacing.lg)
            }
            .background(LuminaColors.parchment)
            .navigationTitle("Enter manually")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Sub-views

    private var blurb: some View {
        Text("Use this when MapKit can't find your birth place. You can copy coordinates from any maps app.")
            .font(LuminaTypography.bodyLight)
            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
    }

    private var nameField: some View {
        LuminaTextField(
            title: "Place name",
            text: $name,
            placeholder: "Stockholm, Sweden",
            helper: "How you'll see it inside the app."
        )
    }

    private var coordinateRow: some View {
        HStack(spacing: LuminaSpacing.md) {
            LuminaTextField(
                title: "Latitude",
                text: $latitudeText,
                placeholder: "59.3293",
                helper: "−90 to 90",
                keyboard: .numbersAndPunctuation
            )
            LuminaTextField(
                title: "Longitude",
                text: $longitudeText,
                placeholder: "18.0686",
                helper: "−180 to 180",
                keyboard: .numbersAndPunctuation
            )
        }
    }

    private var timeZonePicker: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
            Text("TIME ZONE")
                .font(LuminaTypography.caption)
                .tracking(1.2)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            Picker("Time zone", selection: $timeZoneIdentifier) {
                ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { id in
                    Text(id).font(LuminaTypography.body).tag(id)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(LuminaSpacing.sm)
            .background(LuminaColors.parchment)
            .overlay(
                RoundedRectangle(cornerRadius: LuminaRadii.sm, style: .continuous)
                    .stroke(LuminaColors.inkBlack.opacity(0.2), lineWidth: 1)
            )
            .luminaCornerRadius(LuminaRadii.sm)
        }
    }

    // MARK: - Logic

    /// Returns the validated tuple or nil — used both for enabling Save
    /// and for the actual write on Save tap.
    private var validated: (name: String, lat: Double, lon: Double, tz: String)? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              let lat = Double(latitudeText.replacingOccurrences(of: ",", with: ".")),
              let lon = Double(longitudeText.replacingOccurrences(of: ",", with: ".")),
              (-90.0...90.0).contains(lat),
              (-180.0...180.0).contains(lon),
              TimeZone(identifier: timeZoneIdentifier) != nil else {
            return nil
        }
        return (trimmedName, lat, lon, timeZoneIdentifier)
    }

    private func save() {
        guard let validated else {
            error = "Check the values — latitude, longitude, and time zone all need to be real."
            Haptics.failure.play()
            return
        }
        state.applyResolvedPlace(
            name: validated.name,
            latitude: validated.lat,
            longitude: validated.lon,
            timeZoneIdentifier: validated.tz
        )
        Haptics.success.play()
        dismiss()
    }
}

#Preview {
    ManualBirthPlaceSheet(state: OnboardingState(storage: .inMemory()))
}
