import SwiftUI

/// Small wrapper that funnels every destructive action in the app through
/// the same confirmation pattern. Without this, every feature ends up
/// inventing its own "Are you sure?" copy and the brand voice fragments.
///
/// Usage:
/// ```swift
/// .luminaConfirmation(
///     "Delete this entry?",
///     message: "This can't be undone.",
///     confirmTitle: "Delete",
///     isPresented: $showConfirm,
///     onConfirm: { viewModel.delete() }
/// )
/// ```
extension View {
    func luminaConfirmation(
        _ title: String,
        message: String? = nil,
        confirmTitle: String,
        cancelTitle: String = "Keep",
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        confirmationDialog(
            title,
            isPresented: isPresented,
            titleVisibility: .visible
        ) {
            Button(confirmTitle, role: .destructive) {
                Haptics.warning.play()
                onConfirm()
            }
            Button(cancelTitle, role: .cancel) { }
        } message: {
            if let message {
                Text(message)
            }
        }
    }
}
