import SwiftData
import SwiftUI

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
    @State private var addPresented = false
    @State private var qrPresented = false
    @State private var sharePayload: SharePayload?
    @State private var pendingDelete: Friend?

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
        .animation(.smooth, value: pendingDelete?.id)
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
            .transition(.move(edge: .bottom).combined(with: .opacity))
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
                    primaryCTA: LuminaEmptyState.CTA(title: "Add someone", action: presentAdd),
                    secondaryCTA: LuminaEmptyState.CTA(title: "Share my chart", action: presentQR)
                )
                privacyCard
            }
            .padding(LuminaSpacing.lg)
        }
    }

    private var friendsList: some View {
        List {
            Section {
                ForEach(friends.filter { $0.id != pendingDelete?.id }) { friend in
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
                Text("Friends live on this device only. We don't sync names, birthdays, or photos to a server unless you explicitly turn on friend discovery, which is currently off.")
                    .font(LuminaTypography.bodyLight)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
            }
        }
        .padding(.horizontal, LuminaSpacing.lg)
        .padding(.bottom, LuminaSpacing.lg)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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

    private func avatar(for friend: Friend) -> some View {
        ZStack {
            Circle()
                .fill(LuminaColors.parchment)
                .overlay(Circle().stroke(LuminaColors.inkBlack.opacity(0.15), lineWidth: 1))
            Text(initial(for: friend.name))
                .font(LuminaTypography.body)
                .foregroundStyle(LuminaColors.inkBlack)
        }
        .frame(width: 36, height: 36)
    }

    private func initial(for name: String) -> String {
        String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
    }

    private func birthLine(_ friend: Friend) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
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
