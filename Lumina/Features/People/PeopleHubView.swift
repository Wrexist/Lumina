import SwiftData
import SwiftUI

/// Sort orders for the People list, persisted via `@AppStorage`. `@Query`'s
/// sort descriptor is static, so `PeopleHubView` re-sorts the fetched array
/// in a computed property instead of re-querying.
enum FriendSortOrder: String, CaseIterable, Identifiable, Sendable {
    case recentlyAdded
    case name
    case compatibility

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .recentlyAdded: "Recently added"
        case .name: "Name"
        case .compatibility: "Compatibility score"
        }
    }

    func sorted(_ friends: [Friend]) -> [Friend] {
        switch self {
        case .recentlyAdded:
            friends.sorted { $0.createdAt > $1.createdAt }
        case .name:
            friends.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .compatibility:
            friends.sorted(by: Self.compatibilityFirst)
        }
    }

    /// Highest score first; friends without a score sort last (newest first
    /// among themselves, matching the default order).
    private static func compatibilityFirst(_ lhs: Friend, _ rhs: Friend) -> Bool {
        switch (lhs.compatibilityScore, rhs.compatibilityScore) {
        case let (left?, right?) where left != right:
            left > right
        case (.some, .none):
            true
        case (.none, .some):
            false
        default:
            lhs.createdAt > rhs.createdAt
        }
    }
}

/// Phase-7 / Phase-10 People hub. Real list of `Friend`s sorted by
/// recency, manual add, share-my-chart QR. Synastry bi-wheel + the
/// 5-dimension narrative report ship with the backend `/synastry`
/// endpoint in Phase 7.
struct PeopleHubView: View {
    private struct SharePayload: Identifiable {
        let value: String
        var id: String { value }
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @Query(sort: \Friend.createdAt, order: .reverse) private var friends: [Friend]
    @AppStorage("peopleSortOrder") private var sortOrder: FriendSortOrder = .recentlyAdded
    @State private var addPresented = false
    @State private var qrPresented = false
    @State private var sharePayload: SharePayload?
    @State private var pendingDelete: Friend?
    @State private var preferences = AppPreferences.shared
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    /// Effective Reduce Motion — the OS setting or the in-app override.
    private var reduceMotion: Bool {
        LuminaMotion.isReduced(system: systemReduceMotion, appOverride: preferences.reduceMotionOverride)
    }

    var body: some View {
        Group {
            if friends.isEmpty {
                emptyState
            } else {
                friendsList
            }
        }
        .background(LuminaColors.parchment)
        .navigationTitle("People")
        .toolbar { toolbarContent }
        .sheet(isPresented: $addPresented) {
            AddFriendView()
        }
        .sheet(isPresented: $qrPresented) {
            ShareQRView()
        }
        .sheet(item: $sharePayload) { payload in
            AcceptShareView(payload: payload.value)
        }
        .task { consumeShare(router.pendingPresentation) }
        .onChange(of: router.pendingPresentation) { _, link in
            consumeShare(link)
        }
        .overlay(alignment: .bottom) { undoBar }
        .animation(reduceMotion ? nil : .smooth, value: pendingDelete?.id)
        .task(id: pendingDelete?.id) { await autoCommitPendingDelete() }
        .onDisappear(perform: commitPendingDelete)
    }

    @ViewBuilder
    private var undoBar: some View {
        if let pendingDelete {
            LuminaSnackbarView(
                message: "Removed \(pendingDelete.name)",
                actionTitle: "Undo",
                onAction: cancelPendingDelete
            )
            .transition(reduceMotion ? .identity : .move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - View building blocks

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: LuminaSpacing.lg) {
                LuminaEmptyState(
                    systemImage: "person.2",
                    title: "No one here yet",
                    body: "Add a friend, partner, or family member to see what's happening between you.",
                    illustration: .emptyPeople,
                    primaryCTA: LuminaEmptyState.CTA(title: "Add someone", action: presentAdd),
                    secondaryCTA: LuminaEmptyState.CTA(title: "Share my chart", action: presentQR)
                )
                privacyCard
            }
            .padding(LuminaSpacing.lg)
        }
    }

    /// `@Query` always fetches newest-first; the user's chosen order is
    /// applied here so switching it never re-runs the fetch.
    private var sortedFriends: [Friend] {
        sortOrder.sorted(friends)
    }

    private var friendsList: some View {
        List {
            Section {
                ForEach(sortedFriends.filter { $0.id != pendingDelete?.id }) { friend in
                    NavigationLink {
                        FriendDetailView(friend: friend)
                    } label: {
                        friendRow(friend)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            softDelete(friend)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
            Section {
                privacyCard
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(LuminaColors.parchment)
    }

    private var privacyCard: some View {
        LuminaCard {
            VStack(alignment: .leading, spacing: LuminaSpacing.sm) {
                HStack(spacing: LuminaSpacing.sm) {
                    Image(systemName: "lock")
                        .foregroundStyle(LuminaColors.celestialBlue)
                    Text("Privacy")
                        .font(LuminaTypography.heading)
                }
                Text("Names and notes stay on this device — we never send them anywhere. "
                    + "To score compatibility we do send both birth dates and times to our "
                    + "chart service, because that's what the maths needs; it isn't stored "
                    + "there, and locations are never sent.")
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
        }
        .padding(.horizontal, LuminaSpacing.lg)
        .padding(.bottom, LuminaSpacing.lg)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if !friends.isEmpty {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort by", selection: $sortOrder) {
                        ForEach(FriendSortOrder.allCases) { order in
                            Text(order.displayName).tag(order)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                }
                .accessibilityLabel("Sort people")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Add someone", systemImage: "person.fill.badge.plus") {
                    presentAdd()
                }
                Button("Share my chart", systemImage: "qrcode") {
                    presentQR()
                }
            } label: {
                Image(systemName: "plus.circle")
            }
            .accessibilityLabel("Add or share")
        }
    }

    // MARK: - Methods

    /// Soft-delete: hide the friend and start the undo window. Any already-
    /// pending deletion is committed first (one undo at a time).
    private func softDelete(_ friend: Friend) {
        Haptics.warning.play()
        commitPendingDelete()
        pendingDelete = friend
    }

    private func cancelPendingDelete() {
        Haptics.light.play()
        pendingDelete = nil
    }

    /// Waits out the undo window, then finalizes — cancelled automatically when
    /// `pendingDelete` changes (undo, or another deletion supersedes it).
    private func autoCommitPendingDelete() async {
        guard pendingDelete != nil else { return }
        try? await Task.sleep(for: .seconds(4))
        guard !Task.isCancelled else { return }
        commitPendingDelete()
    }

    private func commitPendingDelete() {
        guard let friend = pendingDelete else { return }
        modelContext.delete(friend)
        modelContext.saveOrLog(category: "People")
        pendingDelete = nil
    }

    private func presentAdd() {
        addPresented = true
    }

    private func presentQR() {
        qrPresented = true
    }

    /// Consumes a `lumina://share/<payload>` deep link routed to this tab,
    /// presenting the add-friend confirmation. Ignores links for other tabs.
    private func consumeShare(_ link: LuminaDeepLink?) {
        guard let link, case .acceptShare(let payload) = link else { return }
        sharePayload = SharePayload(value: payload)
        router.pendingPresentation = nil
    }

    private func friendRow(_ friend: Friend) -> some View {
        HStack(spacing: LuminaSpacing.md) {
            avatar(for: friend)
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name).font(LuminaTypography.body)
                Text(birthLine(friend))
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            }
            Spacer()
            if let score = friend.compatibilityScore {
                Text("\(score)")
                    .font(LuminaTypography.mono)
                    .foregroundStyle(LuminaColors.celestialBlue)
            }
        }
        .padding(.vertical, LuminaSpacing.xs)
    }

    /// A night-sky disc carrying the person's Sun-sign constellation — the
    /// real star pattern, not a pictorial ram or crab. The name sits right
    /// beside it, so the disc reads as identity rather than information; the
    /// monogram stays as the fallback for anything the sign lookup can't
    /// place.
    private func avatar(for friend: Friend) -> some View {
        ZStack {
            Circle()
                .fill(LuminaColors.midnight)
                .overlay(Circle().stroke(LuminaColors.mutedGold.opacity(0.3), lineWidth: 1))
            if let constellation = LuminaImageAsset.constellation(sign: sunSign(for: friend)) {
                constellation.image
                    .resizable()
                    .scaledToFit()
                    .padding(LuminaSpacing.xs)
            } else {
                Text(initial(for: friend.name))
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.parchment)
            }
        }
        .frame(width: 36, height: 36)
        .accessibilityHidden(true)
    }

    /// Read in the friend's own birth zone, so someone born just after a cusp
    /// abroad doesn't get the previous sign's constellation.
    private func sunSign(for friend: Friend) -> String {
        ChartGlyphs.sunSign(
            for: friend.birthDate,
            calendar: BirthMoment.calendar(friend.birthTimeZoneIdentifier)
        )
    }

    private func initial(for name: String) -> String {
        String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
    }

    private func birthLine(_ friend: Friend) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        // Read the day in the friend's birth zone so it never shifts here.
        formatter.timeZone = BirthMoment.calendar(friend.birthTimeZoneIdentifier).timeZone
        let date = formatter.string(from: friend.birthDate)
        if let place = friend.birthPlaceName {
            return "\(date) · \(place)"
        }
        return date
    }
}

#Preview {
    NavigationStack { PeopleHubView() }
        .environment(AppRouter(storage: .inMemory()))
        .modelContainer(for: Friend.self, inMemory: true)
}
