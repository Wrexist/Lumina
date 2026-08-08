import SwiftData
import SwiftUI

/// Edit-birth-info form for Settings → Your info. Reuses the same field
/// shapes from the Phase-2 onboarding (`BirthPlaceSearch`,
/// `LuminaTextField`, `WhyWeAsk`) and writes through `UserBirthDataStore`.
///
/// On save we don't force-recompute the chart here — the next visit to
/// the Chart tab triggers a `viewModel.reload()` because birth-data
/// changed. Phase 5 wires an explicit "you changed your time, here's a
/// fresh reading" affordance on Today.
struct EditBirthInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var birthDate = Date.now
    @State private var birthTime = Date.now
    @State private var birthTimeUnknown = false
    @State private var search = BirthPlaceSearch()
    @State private var query = ""
    @State private var resolved: BirthPlaceSearch.Resolved?
    /// Inline message when a tapped suggestion can't be resolved.
    @State private var resolveError: String?
    @State private var hydrated = false
    @State private var manualSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                blurb
                dateField
                timeField
                placeField
                suggestionList
                manualButton
            }
            .padding(LuminaSpacing.lg)
        }
        .background(LuminaColors.parchment)
        .navigationTitle("Your info")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { trailingToolbar }
        .task(id: hydrated) { hydrate() }
        .sheet(isPresented: $manualSheet) {
            ManualBirthPlaceSheetEdit(onResolve: applyManual)
        }
    }

    // MARK: - View building blocks

    private var blurb: some View {
        Text("Update your birth date, time, and place. Your chart re-computes the next time you open the Chart tab.")
            .font(LuminaTypography.bodyLight)
            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
    }

    private var dateField: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
            HStack {
                Text("BIRTH DATE")
                    .font(LuminaTypography.caption)
                    .tracking(1.2)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                Spacer()
                WhyWeAsk(
                    title: "Why we ask for your birth date",
                    body: "Your birth date sets every planet's exact position at the moment you were born."
                )
            }
            DatePicker("Birth date", selection: $birthDate, in: BirthData.selectableBirthDates, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
        }
    }

    private var timeField: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
            HStack {
                Text("BIRTH TIME")
                    .font(LuminaTypography.caption)
                    .tracking(1.2)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                Spacer()
                Toggle("Unknown", isOn: $birthTimeUnknown)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .accessibilityLabel("Birth time unknown")
            }
            if !birthTimeUnknown {
                DatePicker("Birth time", selection: $birthTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }
        }
    }

    private var placeField: some View {
        LuminaTextField(
            title: "Birth place",
            text: queryBinding,
            placeholder: "Stockholm, Sweden",
            helper: resolved == nil
                ? "Pick a city for an exact chart."
                : "Using \(resolved?.displayName ?? "")",
            error: resolveError,
            textContentType: .addressCityAndState
        )
    }

    @ViewBuilder
    private var suggestionList: some View {
        if !search.suggestions.isEmpty {
            VStack(spacing: 0) {
                ForEach(search.suggestions.prefix(5)) { suggestion in
                    Button {
                        Task { await pick(suggestion) }
                    } label: {
                        VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
                            Text(suggestion.title).font(LuminaTypography.body)
                            if !suggestion.subtitle.isEmpty {
                                Text(suggestion.subtitle)
                                    .font(LuminaTypography.caption)
                                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(LuminaSpacing.md)
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
            .background(LuminaColors.parchment)
            .luminaCornerRadius(LuminaRadii.sm)
            .overlay(
                RoundedRectangle(cornerRadius: LuminaRadii.sm, style: .continuous)
                    .stroke(LuminaColors.inkBlack.opacity(0.12), lineWidth: 1)
            )
        }
    }

    private var manualButton: some View {
        LuminaButton(title: "Enter coordinates manually", variant: .ghost) {
            manualSheet = true
        }
    }

    @ToolbarContentBuilder
    private var trailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Save") { save() }
                .disabled(!isValid)
                .bold()
        }
    }

    private var queryBinding: Binding<String> {
        Binding(
            get: { query },
            set: { newValue in
                query = newValue
                resolved = nil
                search.update(query: newValue)
            }
        )
    }

    private var isValid: Bool {
        resolved != nil
    }

    // MARK: - Methods

    private func hydrate() {
        guard !hydrated, let existing = UserBirthDataStore.userDefaults.load() else {
            hydrated = true
            return
        }
        let pickers = BirthMoment.pickerValues(
            birthDate: existing.birthDate,
            birthTime: existing.birthTime,
            timeZoneIdentifier: existing.timeZoneIdentifier
        )
        birthDate = pickers.day
        if let time = pickers.time {
            birthTime = time
            birthTimeUnknown = false
        } else {
            birthTimeUnknown = true
        }
        query = existing.placeName
        resolved = BirthPlaceSearch.Resolved(
            displayName: existing.placeName,
            latitude: existing.latitude,
            longitude: existing.longitude,
            timeZoneIdentifier: existing.timeZoneIdentifier
        )
        hydrated = true
    }

    private func pick(_ suggestion: BirthPlaceSearch.Suggestion) async {
        do {
            let result = try await search.resolve(suggestion)
            resolved = result
            resolveError = nil
            query = result.displayName
            Haptics.success.play()
        } catch {
            // Was a bare haptic: offline or on a flaky network the user
            // tapped a city, felt a buzz, and the field simply didn't fill —
            // no message, and Save stayed disabled with no explanation. The
            // onboarding equivalent already surfaced this properly.
            resolveError = LuminaError.from(error).userBody
            Haptics.failure.play()
        }
    }

    private func applyManual(_ result: BirthPlaceSearch.Resolved) {
        resolved = result
        query = result.displayName
    }

    private func save() {
        guard let resolved else { return }
        // Picker values are device-local wall clock; anchor them at the
        // birth place before they reach the ephemeris.
        let (anchoredDate, anchoredTime) = BirthMoment.combine(
            pickedDay: birthDate,
            pickedTime: birthTimeUnknown ? nil : birthTime,
            timeZoneIdentifier: resolved.timeZoneIdentifier
        )
        let birthData = BirthData(
            birthDate: anchoredDate,
            birthTime: anchoredTime,
            placeName: resolved.displayName,
            latitude: resolved.latitude,
            longitude: resolved.longitude,
            timeZoneIdentifier: resolved.timeZoneIdentifier
        )
        UserBirthDataStore.userDefaults.save(birthData)
        clearCachedFriendScores()
        Haptics.success.play()
        dismiss()
    }

    /// Cached `Friend.compatibilityScore` values were computed against the
    /// user's OLD birth data, so they are wrong the moment it changes.
    /// Clear them — they are re-derived from real synastry cross-aspects the
    /// next time each friend's detail screen loads. This used to recompute a
    /// Sun-sign heuristic instead, which replaced a stale fabricated number
    /// with a fresh fabricated one.
    private func clearCachedFriendScores() {
        guard let friends = try? modelContext.fetch(FetchDescriptor<Friend>()) else { return }
        for friend in friends {
            friend.compatibilityScore = nil
        }
        modelContext.saveOrLog(category: "Settings")
    }
}

/// Wraps `ManualBirthPlaceSheet` for the Settings flow. The onboarding
/// sheet writes through `OnboardingState.applyResolvedPlace`; here we
/// surface the resolved tuple back to the parent via callback so it can
/// merge with the existing birth date/time.
private struct ManualBirthPlaceSheetEdit: View {
    let onResolve: (BirthPlaceSearch.Resolved) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var latitudeText = ""
    @State private var longitudeText = ""
    @State private var timeZoneIdentifier = TimeZone.current.identifier
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                    LuminaTextField(title: "Place name", text: $name, placeholder: "Stockholm, Sweden")
                    HStack(spacing: LuminaSpacing.md) {
                        LuminaTextField(title: "Latitude", text: $latitudeText, placeholder: "59.3293", helper: "−90 to 90", keyboard: .numbersAndPunctuation)
                        LuminaTextField(title: "Longitude", text: $longitudeText, placeholder: "18.0686", helper: "−180 to 180", keyboard: .numbersAndPunctuation)
                    }
                    TimeZonePickerField(identifier: $timeZoneIdentifier)
                    if let error {
                        Text(error)
                            .font(LuminaTypography.caption)
                            .foregroundStyle(LuminaColors.error)
                    }
                    LuminaButton(title: "Save", variant: .primary, isEnabled: validated != nil) { save() }
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

    private var validated: BirthPlaceSearch.Resolved? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let lat = Double(latitudeText.replacingOccurrences(of: ",", with: ".")),
              let lon = Double(longitudeText.replacingOccurrences(of: ",", with: ".")),
              (-90.0...90.0).contains(lat),
              (-180.0...180.0).contains(lon),
              TimeZone(identifier: timeZoneIdentifier) != nil else {
            return nil
        }
        return BirthPlaceSearch.Resolved(
            displayName: trimmed,
            latitude: lat,
            longitude: lon,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }

    private func save() {
        guard let validated else {
            error = "Check the values."
            Haptics.failure.play()
            return
        }
        Haptics.success.play()
        onResolve(validated)
        dismiss()
    }
}
