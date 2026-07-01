import SwiftData
import SwiftUI

/// Manual friend-add form. Reuses the Phase-2 `BirthPlaceSearch` for
/// MapKit autocomplete plus a "skip" path for friends whose birth time /
/// place we don't know yet.
struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var birthDate: Date = .now
    @State private var birthTime: Date = .now
    @State private var birthTimeUnknown = true
    @State private var search = BirthPlaceSearch()
    @State private var query = ""
    @State private var resolved: BirthPlaceSearch.Resolved?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                    blurb
                    nameField
                    dateField
                    timeField
                    placeField
                    suggestionList
                }
                .padding(LuminaSpacing.lg)
            }
            .background(LuminaColors.parchment)
            .navigationTitle("Add someone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }

    // MARK: - Sub-views

    private var blurb: some View {
        Text("A name and a birth date are enough. Time and place sharpen the chart but aren't required.")
            .font(LuminaTypography.bodyLight)
            .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
    }

    private var nameField: some View {
        LuminaTextField(
            title: "Name",
            text: $name,
            placeholder: "Sam",
            helper: "How they show up in your list.",
            textContentType: .givenName,
            maxCharacters: 60
        )
    }

    private var dateField: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
            Text("BIRTH DATE")
                .font(LuminaTypography.caption)
                .tracking(1.2)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            DatePicker("Birth date", selection: $birthDate, in: ...Date.now, displayedComponents: .date)
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
        VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
            LuminaTextField(
                title: "Birth place",
                text: queryBinding,
                placeholder: "Stockholm, Sweden",
                helper: resolved == nil
                    ? "Optional — pick a city for an exact chart."
                    : "Using \(resolved?.displayName ?? "")",
                textContentType: .addressCityAndState
            )
        }
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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") { dismiss() }
        }
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

    // MARK: - Logic

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func pick(_ suggestion: BirthPlaceSearch.Suggestion) async {
        do {
            let result = try await search.resolve(suggestion)
            resolved = result
            query = result.displayName
            Haptics.success.play()
        } catch {
            Haptics.failure.play()
        }
    }

    private func save() {
        let friend = Friend(
            name: name.trimmingCharacters(in: .whitespaces),
            birthDate: birthDate,
            birthTime: birthTimeUnknown ? nil : birthTime,
            birthPlaceName: resolved?.displayName,
            birthLatitude: resolved?.latitude,
            birthLongitude: resolved?.longitude,
            birthTimeZoneIdentifier: resolved?.timeZoneIdentifier,
            source: .manual
        )
        if let userBirth = UserBirthDataStore.userDefaults.load() {
            friend.compatibilityScore = CompatibilityScorer.score(userBirth.birthDate, friend.birthDate)
        }
        modelContext.insert(friend)
        modelContext.saveOrLog(category: "People")
        Haptics.success.play()
        dismiss()
    }
}

#Preview {
    AddFriendView()
        .modelContainer(for: Friend.self, inMemory: true)
}
