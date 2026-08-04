import SwiftUI

/// One row of the Settings list: a title, an optional trailing value, and
/// nothing else.
///
/// Its own file because `SettingsView` sits against SwiftLint's 400-line
/// file ceiling, and because this is a component rather than a screen —
/// `AcknowledgementsView` and anything else built on the same list style can
/// use it directly.
struct SettingsRow: View {
    enum Trailing {
        case text(String)
    }

    let title: String
    var trailing: Trailing?

    var body: some View {
        HStack {
            Text(title).font(LuminaTypography.body)
            Spacer()
            switch trailing {
            case .text(let value):
                Text(value)
                    .font(LuminaTypography.body)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            case nil:
                EmptyView()
            }
            // No manual chevron: NavigationLink rows get the system disclosure
            // indicator automatically, so plain rows correctly show none
            // rather than a misleading affordance.
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        SettingsRow(title: "Manage subscription", trailing: nil)
        SettingsRow(title: "Status", trailing: .text("Active"))
    }
}
