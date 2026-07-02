import SwiftUI

/// Shared time-zone selector. Renders as a labelled row showing the
/// currently selected IANA identifier; tapping it opens a sheet with a
/// searchable list of `TimeZone.knownTimeZoneIdentifiers` (~600 entries).
/// Replaces the giant `.menu` pickers that used to be duplicated in
/// onboarding's `ManualBirthPlaceSheet` and Settings → Edit birth info.
struct TimeZonePickerField: View {
    @Binding var identifier: String
    @State private var pickerPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
            Text("TIME ZONE")
                .font(LuminaTypography.caption)
                .tracking(1.2)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            row
        }
        .sheet(isPresented: $pickerPresented) {
            TimeZonePickerSheet(identifier: $identifier)
        }
    }

    private var row: some View {
        Button {
            pickerPresented = true
        } label: {
            HStack(spacing: LuminaSpacing.sm) {
                Text(identifier)
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.5))
            }
            .padding(LuminaSpacing.md)
            .background(LuminaColors.parchment)
            .overlay(
                RoundedRectangle(cornerRadius: LuminaRadii.sm, style: .continuous)
                    .stroke(LuminaColors.inkBlack.opacity(0.2), lineWidth: 1)
            )
            .luminaCornerRadius(LuminaRadii.sm)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Time zone")
        .accessibilityValue(identifier)
        .accessibilityHint("Opens a searchable list")
    }

    /// Case-insensitive substring filter over the identifier list; an
    /// empty or whitespace-only query returns everything. `nonisolated`
    /// and injectable so unit tests can exercise it directly.
    nonisolated static func filteredIdentifiers(
        matching query: String,
        in identifiers: [String] = TimeZone.knownTimeZoneIdentifiers
    ) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return identifiers }
        return identifiers.filter { $0.range(of: trimmed, options: .caseInsensitive) != nil }
    }
}

/// The searchable list the row presents. Plain (ungrouped) list — the
/// identifiers already read hierarchically (`Europe/Stockholm`), so extra
/// section chrome would only slow scanning.
private struct TimeZonePickerSheet: View {
    @Binding var identifier: String
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filtered: [String] {
        TimeZonePickerField.filteredIdentifiers(matching: query)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: LuminaSpacing.sm) {
                LuminaTextField(
                    title: "Search",
                    text: $query,
                    placeholder: "City or region, e.g. Stockholm"
                )
                .padding(.horizontal, LuminaSpacing.lg)
                .padding(.top, LuminaSpacing.md)
                identifierList
            }
            .background(LuminaColors.parchment)
            .navigationTitle("Time zone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var identifierList: some View {
        List(filtered, id: \.self) { candidate in
            Button {
                identifier = candidate
                dismiss()
            } label: {
                HStack {
                    Text(candidate).font(LuminaTypography.body)
                    Spacer()
                    if candidate == identifier {
                        Image(systemName: "checkmark")
                            .foregroundStyle(LuminaColors.celestialBlue)
                            .accessibilityLabel("Selected")
                    }
                }
            }
            .buttonStyle(.plain)
            .listRowBackground(LuminaColors.parchment)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    TimeZonePickerField(identifier: .constant("Europe/Stockholm"))
        .padding(LuminaSpacing.lg)
        .background(LuminaColors.parchment)
}
