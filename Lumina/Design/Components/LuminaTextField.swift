import SwiftUI

/// Single-line input with brand styling, an inline error slot, and an
/// optional helper / character counter line. Onboarding and Settings reuse
/// this everywhere — there is no second text-field component.
struct LuminaTextField: View {
    let title: String
    @Binding var text: String
    var placeholder = ""
    var helper: String?
    var error: String?
    var isSecure = false
    var keyboard: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var maxCharacters: Int?

    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: LuminaSpacing.xs) {
            Text(title.uppercased())
                .font(LuminaTypography.caption)
                .foregroundStyle(LuminaColors.inkBlack.opacity(0.7))
                .tracking(1.2)

            field
                .focused($focused)
                .keyboardType(keyboard)
                .textContentType(textContentType)
                .padding(LuminaSpacing.md)
                .background(LuminaColors.parchment)
                .overlay(
                    RoundedRectangle(cornerRadius: LuminaRadii.sm, style: .continuous)
                        .stroke(borderColor, lineWidth: focused ? 2 : 1)
                )
                .luminaCornerRadius(LuminaRadii.sm)
                // The label and any helper/error text are attached to the
                // FIELD itself, so VoiceOver announces them while keeping the
                // text-field trait and direct editing.
                //
                // This whole VStack used to carry
                // `.accessibilityElement(children: .combine)`, which merges
                // children into one static element and strips the text-field
                // trait. This is the only text-input component in the app —
                // it backs the onboarding name and birth-place fields, Add
                // Friend, Edit Birth Info, feedback and Ask-your-chart — so
                // VoiceOver users heard "Your name, Empty" as static text and
                // could not type into it. Onboarding was unfinishable.
                .accessibilityLabel(title)
                .accessibilityValue(accessibilityValueText)
                .accessibilityHint(accessibilityHintText)

            // Decorative once the text above is announced as the field's hint;
            // leaving it visible to VoiceOver would read the error twice.
            footer
                .accessibilityHidden(true)
        }
    }

    /// Helper text and validation errors, spoken as the field's hint so the
    /// user hears *why* their input was rejected without leaving the field.
    private var accessibilityHintText: String {
        [helper, error].compactMap { $0 }.joined(separator: ". ")
    }

    private var accessibilityValueText: String {
        if text.isEmpty { return "Empty" }
        // Never read a secure field's contents aloud to VoiceOver.
        return isSecure ? "Filled" : text
    }

    @ViewBuilder
    private var field: some View {
        if isSecure {
            SecureField(placeholder, text: $text)
                .font(LuminaTypography.body)
        } else {
            TextField(placeholder, text: $text)
                .font(LuminaTypography.body)
        }
    }

    @ViewBuilder
    private var footer: some View {
        if let error, !error.isEmpty {
            Text(error)
                .font(LuminaTypography.caption)
                .foregroundStyle(errorColor)
        } else if let helper, !helper.isEmpty {
            HStack {
                Text(helper)
                    .font(LuminaTypography.caption)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                if let maxCharacters {
                    Spacer()
                    Text("\(text.count)/\(maxCharacters)")
                        .font(LuminaTypography.mono)
                        .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
                }
            }
        } else if let maxCharacters {
            HStack {
                Spacer()
                Text("\(text.count)/\(maxCharacters)")
                    .font(LuminaTypography.mono)
                    .foregroundStyle(LuminaColors.inkBlack.opacity(0.6))
            }
        }
    }

    private var borderColor: Color {
        if error != nil { return errorColor }
        return focused ? LuminaColors.celestialBlue : LuminaColors.inkBlack.opacity(0.2)
    }

    private var errorColor: Color {
        LuminaColors.error
    }
}

#Preview("States") {
    VStack(alignment: .leading, spacing: LuminaSpacing.lg) {
        LuminaTextField(
            title: "Your name",
            text: .constant("Anna"),
            placeholder: "Enter your name",
            helper: "Used only to greet you."
        )
        LuminaTextField(
            title: "Birth place",
            text: .constant("Stoc"),
            placeholder: "City, country",
            error: "City not found — try a nearby one."
        )
    }
    .padding(LuminaSpacing.lg)
    .background(LuminaColors.parchment)
}
