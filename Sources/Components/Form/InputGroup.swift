import SwiftUI

// MARK: - InputGroup

struct AppInputGroup<Content: View>: View {
    let content: Content
    var height: CGFloat? = 36
    var cornerRadius: CGFloat = 6
    var borderColor: Color = .gray.opacity(0.3)
    var focusBorderColor: Color = .blue
    var errorBorderColor: Color = .red
    var background: AnyShapeStyle = AnyShapeStyle(Color.clear)
    var isError: Bool = false
    var isDisabled: Bool = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 0) {
            content
        }
        .frame(height: height)
        .background(background)
        .cornerRadius(cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(isError ? errorBorderColor : borderColor, lineWidth: 1)
        )
        .disabled(isDisabled)
    }

    func height(_ value: CGFloat?) -> Self { configure { $0.height = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }
    func errorBorderColor(_ value: Color) -> Self { configure { $0.errorBorderColor = value } }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func error(_ value: Bool) -> Self { configure { $0.isError = value } }
    func disabled(_ value: Bool) -> Self { configure { $0.isDisabled = value } }
}

// MARK: - InputGroupAddon Alignment

enum InputGroupAddonAlign {
    case inlineStart
    case inlineEnd
    case blockStart
    case blockEnd
}

// MARK: - InputGroupAddon

struct AppInputGroupAddon<Content: View>: View {
    let content: Content
    var align: InputGroupAddonAlign = .inlineStart
    var spacing: CGFloat = 8
    var horizontalPadding: CGFloat = 12
    var verticalPadding: CGFloat = 6
    var fontSize: CGFloat = 14
    var fontWeight: Font.Weight = .medium
    var textColor: Color = .secondary
    var isDisabled: Bool = false

    init(align: InputGroupAddonAlign = .inlineStart, @ViewBuilder content: () -> Content) {
        self.align = align
        self.content = content()
    }

    var body: some View {
        HStack(spacing: spacing) {
            content
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(isDisabled ? textColor.opacity(0.5) : textColor)
        }
        .padding(.leading, leadingPadding)
        .padding(.trailing, trailingPadding)
        .padding(.vertical, verticalPadding)
    }

    private var leadingPadding: CGFloat {
        switch align {
        case .inlineStart, .blockStart, .blockEnd: horizontalPadding
        case .inlineEnd: 0
        }
    }

    private var trailingPadding: CGFloat {
        switch align {
        case .inlineEnd, .blockStart, .blockEnd: horizontalPadding
        case .inlineStart: 0
        }
    }

    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
    func padding(horizontal: CGFloat) -> Self { configure { $0.horizontalPadding = horizontal } }
    func padding(vertical: CGFloat) -> Self { configure { $0.verticalPadding = vertical } }

    func font(size: CGFloat, weight: Font.Weight = .medium) -> Self {
        configure { $0.fontSize = size; $0.fontWeight = weight }
    }

    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func disabled(_ value: Bool) -> Self { configure { $0.isDisabled = value } }
}

// MARK: - InputGroupButton Size

enum InputGroupButtonSize {
    case xs
    case sm
    case iconXs
    case iconSm
}

// MARK: - InputGroupButton

struct AppInputGroupButton: View {
    let action: () -> Void
    var title: String?
    var icon: String?
    var size: InputGroupButtonSize = .xs
    var textColor: Color = .primary
    var isDisabled: Bool = false

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: spacing) {
                if let icon {
                    SafeIcon(icon, size: iconSize, color: isDisabled ? textColor.opacity(0.5) : textColor)
                }
                if let title, !isIconOnly {
                    Text(title)
                        .font(.system(size: textSize))
                }
            }
            .foregroundColor(isDisabled ? textColor.opacity(0.5) : textColor)
            .frame(width: isIconOnly ? buttonSize : nil, height: buttonSize)
            .padding(.horizontal, isIconOnly ? 0 : horizontalPadding)
        }
        .background(Color.clear)
        .cornerRadius(cornerRadius)
        .disabled(isDisabled)
    }

    private var isIconOnly: Bool { size == .iconXs || size == .iconSm }

    private var buttonSize: CGFloat {
        switch size {
        case .xs, .iconXs: 24
        case .sm, .iconSm: 32
        }
    }

    private var iconSize: CGFloat {
        switch size {
        case .xs, .iconXs: 14
        case .sm, .iconSm: 16
        }
    }

    private var textSize: CGFloat { 14 }

    private var horizontalPadding: CGFloat {
        switch size {
        case .xs, .iconXs: 8
        case .sm, .iconSm: 10
        }
    }

    private var spacing: CGFloat {
        switch size {
        case .xs, .iconXs: 4
        case .sm, .iconSm: 6
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .xs, .iconXs: 4
        case .sm, .iconSm: 6
        }
    }

    func title(_ value: String) -> Self { configure { $0.title = value } }
    func icon(_ value: String) -> Self { configure { $0.icon = value } }
    func size(_ value: InputGroupButtonSize) -> Self { configure { $0.size = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func disabled(_ value: Bool) -> Self { configure { $0.isDisabled = value } }
}

// MARK: - InputGroupText

struct AppInputGroupText: View {
    let text: String
    var fontSize: CGFloat = 14
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

    func font(size: CGFloat) -> Self { configure { $0.fontSize = size } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func disabled(_ value: Bool) -> Self { configure { $0.isDisabled = value } }
}

// MARK: - InputGroupInput

struct AppInputGroupInput: View {
    @Binding var text: String
    var placeholder: String = ""
    var fontSize: CGFloat = 14
    var textColor: Color = .primary
    var leadingPadding: CGFloat = 4
    var trailingPadding: CGFloat = 4
    var isDisabled: Bool = false

    init(text: Binding<String>, placeholder: String = "") {
        _text = text
        self.placeholder = placeholder
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.system(size: fontSize))
            .foregroundColor(isDisabled ? textColor.opacity(0.5) : textColor)
            .textFieldStyle(PlainTextFieldStyle())
            .padding(.leading, leadingPadding)
            .padding(.trailing, trailingPadding)
            .disabled(isDisabled)
    }

    func font(size: CGFloat) -> Self { configure { $0.fontSize = size } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func padding(leading: CGFloat) -> Self { configure { $0.leadingPadding = leading } }
    func padding(trailing: CGFloat) -> Self { configure { $0.trailingPadding = trailing } }

    func padding(leading: CGFloat, trailing: CGFloat) -> Self {
        configure { $0.leadingPadding = leading; $0.trailingPadding = trailing }
    }

    func disabled(_ value: Bool) -> Self { configure { $0.isDisabled = value } }
}

// MARK: - InputGroupTextarea

struct AppInputGroupTextarea: View {
    @Binding var text: String
    var placeholder: String = ""
    var fontSize: CGFloat = 14
    var textColor: Color = .primary
    var placeholderColor: Color = .secondary
    var leadingPadding: CGFloat = 4
    var trailingPadding: CGFloat = 4
    var verticalPadding: CGFloat = 12
    var isDisabled: Bool = false

    init(text: Binding<String>, placeholder: String = "") {
        _text = text
        self.placeholder = placeholder
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: fontSize))
                    .foregroundColor(isDisabled ? placeholderColor.opacity(0.5) : placeholderColor)
                    .padding(.leading, leadingPadding)
                    .padding(.trailing, trailingPadding)
                    .padding(.vertical, verticalPadding)
            }

            TextEditor(text: $text)
                .font(.system(size: fontSize))
                .foregroundColor(isDisabled ? textColor.opacity(0.5) : textColor)
                .padding(.leading, max(0, leadingPadding - 5))
                .padding(.trailing, max(0, trailingPadding - 5))
                .padding(.vertical, max(0, verticalPadding - 8))
                .disabled(isDisabled)
                .background(Color.clear)
        }
    }

    func font(size: CGFloat) -> Self { configure { $0.fontSize = size } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func placeholderColor(_ value: Color) -> Self { configure { $0.placeholderColor = value } }

    func padding(leading: CGFloat, trailing: CGFloat) -> Self {
        configure { $0.leadingPadding = leading; $0.trailingPadding = trailing }
    }

    func padding(vertical: CGFloat) -> Self { configure { $0.verticalPadding = vertical } }
    func disabled(_ value: Bool) -> Self { configure { $0.isDisabled = value } }
}
