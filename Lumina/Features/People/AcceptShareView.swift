import SwiftData
import SwiftUI

/// Presented when the user opens a `lumina://share/<payload>` link or a
/// `https://lumina.app/share/<payload>` universal link (e.g. by scanning a
/// friend's QR) — both schemes are parsed by `LuminaDeepLink` and route here
/// with an already-decoded `payload`, so this view doesn't care which one
/// produced it. Decodes the reduced `SharedBirthData` and offers to add the
/// person to People. Malformed payloads fall through to a friendly error
/// rather than crashing.
struct AcceptShareView: View {
    let payload: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var shared: SharedBirthData?
    @State private var decoded = false
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Group {
                if let shared {
                    content(shared)
                } else if decoded {
                    LuminaErrorState(
                        error: .unknown(underlyingMessage: "This share link couldn't be read. Ask them to show it again."),
                        onCancel: dismissSheet
                    )
                } else {
                    LuminaSkeleton(shape: .block(height: 160))
                        .padding(LuminaSpacing.lg)
                }
            }
            .background(LuminaColors.parchment)
            .navigationTitle("Add to People")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: dismissSheet)
                }
            }
            .task { decode() }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Sub-views

    private func content(_ shared: SharedBirthData) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
                Text("Someone shared their chart with you. Add them to compare what's between you.")
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                LuminaTextField(title: "Name", text: $name, placeholder: "Their name", maxCharacters: 60)
                LuminaCard {
                    VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                        infoRow("Birth date", dateString(shared))
                        infoRow("City", shared.placeName)
                        infoRow("Birth time", "Not shared")
                    }
                }
                LuminaButton(title: "Add to People", variant: .primary, isEnabled: !trimmedName.isEmpty) {
                    add(shared)
                }
            }
            .padding(LuminaSpacing.lg)
        }
    }

    private func infoRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key.uppercased())
                .font(LuminaTypography.mono)
                .tracking(1.2)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            Spacer()
            Text(value).font(LuminaTypography.body)
        }
    }

    // MARK: - Logic

    private func decode() {
        guard !decoded else { return }
        decoded = true
        guard let data = Data(base64URLEncoded: payload),
              let value = try? JSONDecoder.luminaShare.decode(SharedBirthData.self, from: data) else {
            return
        }
        shared = value
        name = value.name ?? ""
    }

    private func dateString(_ shared: SharedBirthData) -> String {
        // Format in the shared time zone so the day never shifts on the
        // recipient's device.
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeZone = BirthMoment.calendar(shared.timeZoneIdentifier).timeZone
        return formatter.string(from: shared.birthDate)
    }

    private func add(_ shared: SharedBirthData) {
        // Re-scanning the same QR shouldn't silently duplicate the person.
        let incomingDate = shared.birthDate
        if let existing = try? modelContext.fetch(FetchDescriptor<Friend>()),
           existing.contains(where: { $0.birthDate == incomingDate && $0.birthPlaceName == shared.placeName }) {
            Haptics.success.play()
            dismiss()
            return
        }
        let friend = Friend(
            name: trimmedName,
            birthDate: shared.birthDate,
            birthTime: nil,
            birthPlaceName: shared.placeName,
            birthLatitude: shared.latitude,
            birthLongitude: shared.longitude,
            birthTimeZoneIdentifier: shared.timeZoneIdentifier,
            source: .qr
        )
        // Deliberately NOT seeded with a Sun-sign heuristic. The score is
        // only ever written from real synastry cross-aspects (see
        // `FriendDetailView.applyLoadedAspects`), so People shows no number
        // until one exists rather than a hash-derived placeholder.
        modelContext.insert(friend)
        modelContext.saveOrLog(category: "People")
        // A friend accepted via QR counts the same as one added by hand.
        // The duplicate early-return above deliberately doesn't unlock —
        // no new person was saved. `Haptics.success` below already covers
        // the newly-unlocked case.
        MomentsStore.shared.unlock(.firstFriend)
        Haptics.success.play()
        dismiss()
    }

    private func dismissSheet() {
        dismiss()
    }
}

#Preview {
    AcceptShareView(payload: "")
        .modelContainer(for: Friend.self, inMemory: true)
}
