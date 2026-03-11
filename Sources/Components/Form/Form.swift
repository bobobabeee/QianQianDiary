import SwiftUI

// MARK: - Form

struct AppForm<Content: View>: View {
    let content: Content
    var spacing: CGFloat = 16
    var alignment: HorizontalAlignment = .leading

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            content
        }
    }

    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
    func alignment(_ value: HorizontalAlignment) -> Self { configure { $0.alignment = value } }
}

// MARK: - FormItem

struct AppFormItem<Content: View>: View {
    let content: Content
    var spacing: CGFloat = 8
    var alignment: HorizontalAlignment = .leading

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            content
        }
    }

    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
    func alignment(_ value: HorizontalAlignment) -> Self { configure { $0.alignment = value } }
}

// MARK: - FormLabel

struct AppFormLabel: View {
    let text: String
    var fontSize: CGFloat = 14
    var fontWeight: Font.Weight = .medium
    var textColor: Color = .primary
    var errorColor: Color = .red
    var requiredColor: Color = .red
    var isRequired: Bool = false
    var hasError: Bool = false
    var isDisabled: Bool = false

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(spacing: 2) {
            Text(text)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(computedTextColor)

            if isRequired {
                Text("*")
                    .font(.system(size: fontSize, weight: fontWeight))
                    .foregroundColor(computedRequiredColor)
            }
        }
    }

    private var computedTextColor: Color {
        let baseColor = hasError ? errorColor : textColor
        return isDisabled ? baseColor.opacity(0.5) : baseColor
    }

    private var computedRequiredColor: Color {
        isDisabled ? requiredColor.opacity(0.5) : requiredColor
    }

    func required(_ value: Bool = true) -> Self { configure { $0.isRequired = value } }
    func hasError(_ value: Bool = true) -> Self { configure { $0.hasError = value } }
    func disabled(_ value: Bool = true) -> Self { configure { $0.isDisabled = value } }
    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func fontWeight(_ value: Font.Weight) -> Self { configure { $0.fontWeight = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func errorColor(_ value: Color) -> Self { configure { $0.errorColor = value } }
    func requiredColor(_ value: Color) -> Self { configure { $0.requiredColor = value } }
}

// MARK: - FormControl

struct AppFormControl<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
    }
}

// MARK: - FormDescription

struct AppFormDescription: View {
    let text: String
    var fontSize: CGFloat = 12
    var textColor: Color = .secondary
    var isDisabled: Bool = false

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .foregroundColor(isDisabled ? textColor.opacity(0.5) : textColor)
    }

    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func disabled(_ value: Bool = true) -> Self { configure { $0.isDisabled = value } }
}

// MARK: - FormMessage

struct AppFormMessage: View {
    let text: String?
    var fontSize: CGFloat = 12
    var fontWeight: Font.Weight = .medium
    var textColor: Color = .red

    init(_ text: String?) {
        self.text = text
    }

    var body: some View {
        if let text, !text.isEmpty {
            Text(text)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(textColor)
        }
    }

    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func fontWeight(_ value: Font.Weight) -> Self { configure { $0.fontWeight = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
}
