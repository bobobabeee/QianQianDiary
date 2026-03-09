import Popovers
import SwiftUI

// MARK: - Select

struct AppSelect<T: Hashable, Content: View>: View {
    @Binding var selection: T
    var placeholder: String = "Select..."
    var displayValue: String?
    var fontSize: CGFloat = 14
    var iconSize: CGFloat = 16
    var height: CGFloat = 36
    var cornerRadius: CGFloat = 6
    var borderColor: Color = .gray.opacity(0.3)
    var background: AnyShapeStyle = AnyShapeStyle(Color(UIColor.systemBackground))
    var contentInsets: CGFloat = 4
    var horizontalInsets: CGFloat = 12
    var maxHeight: CGFloat = 256
    var minWidth: CGFloat = 128
    var accentColor: Color = SelectColors.accent
    var shadowColor: Color = .black.opacity(0.15)
    var shadowRadius: CGFloat = 8
    var popoverBorderColor: Color = .gray.opacity(0.2)
    let content: Content

    @State private var isPresented: Bool = false
    @State private var triggerWidth: CGFloat = 0

    init(
        selection: Binding<T>,
        displayValue: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        _selection = selection
        self.displayValue = displayValue
        self.content = content()
    }

    var body: some View {
        selectTrigger
            .background(
                GeometryReader { geometry in
                    Color.clear.onAppear {
                        triggerWidth = geometry.size.width
                    }
                    .onChange(of: geometry.size.width) { newWidth in
                        triggerWidth = newWidth
                    }
                }
            )
            .appPopover(
                isPresented: $isPresented,
                side: .auto,
                sideOffset: 4
            ) {
                selectContentView
            }
    }

    private var selectTrigger: some View {
        Button(action: { isPresented.toggle() }) {
            HStack {
                if let display = displayValue, !display.isEmpty {
                    Text(display)
                        .font(.system(size: fontSize))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                } else {
                    Text(placeholder)
                        .font(.system(size: fontSize))
                        .foregroundColor(.secondary)
                }
                Spacer()
                SafeIcon("ChevronDown", size: iconSize, color: .primary.opacity(0.5))
            }
            .padding(.horizontal, horizontalInsets)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background(background)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var selectContentView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .padding(contentInsets)
        }
        .frame(width: max(triggerWidth, minWidth))
        .frame(maxHeight: maxHeight)
        .fixedSize(horizontal: false, vertical: true)
        .background(background)
        .cornerRadius(cornerRadius)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(popoverBorderColor, lineWidth: 1)
        )
        .environment(\.selectSelection, SelectionWrapper(value: selection, isEqual: { $0 as? T == selection }))
        .environment(\.selectAccentColor, accentColor)
        .environment(\.selectOnSelect) { [self] value in
            if let v = value as? T {
                selection = v
                isPresented = false
            }
        }
    }

    func placeholder(_ value: String) -> Self { configure { $0.placeholder = value } }
    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func iconSize(_ value: CGFloat) -> Self { configure { $0.iconSize = value } }
    func height(_ value: CGFloat) -> Self { configure { $0.height = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func horizontalInsets(_ value: CGFloat) -> Self { configure { $0.horizontalInsets = value } }
    func contentInsets(_ value: CGFloat) -> Self { configure { $0.contentInsets = value } }
    func maxHeight(_ value: CGFloat) -> Self { configure { $0.maxHeight = value } }
    func minWidth(_ value: CGFloat) -> Self { configure { $0.minWidth = value } }
    func accentColor(_ value: Color) -> Self { configure { $0.accentColor = value } }
    func shadowColor(_ value: Color) -> Self { configure { $0.shadowColor = value } }
    func shadowRadius(_ value: CGFloat) -> Self { configure { $0.shadowRadius = value } }
    func popoverBorderColor(_ value: Color) -> Self { configure { $0.popoverBorderColor = value } }
}

// MARK: - Environment Keys

private struct SelectSelectionKey: EnvironmentKey {
    static let defaultValue: SelectionWrapper? = nil
}

private struct SelectOnSelectKey: EnvironmentKey {
    static let defaultValue: ((Any) -> Void)? = nil
}

private struct SelectAccentColorKey: EnvironmentKey {
    static let defaultValue: Color = SelectColors.accent
}

struct SelectionWrapper {
    let value: Any
    let isEqual: (Any) -> Bool
}

extension EnvironmentValues {
    var selectSelection: SelectionWrapper? {
        get { self[SelectSelectionKey.self] }
        set { self[SelectSelectionKey.self] = newValue }
    }

    var selectOnSelect: ((Any) -> Void)? {
        get { self[SelectOnSelectKey.self] }
        set { self[SelectOnSelectKey.self] = newValue }
    }

    var selectAccentColor: Color {
        get { self[SelectAccentColorKey.self] }
        set { self[SelectAccentColorKey.self] = newValue }
    }
}

// MARK: - Select Item

struct AppSelectItem<T: Hashable>: View {
    @Environment(\.selectSelection) private var selection
    @Environment(\.selectOnSelect) private var onSelect
    @Environment(\.selectAccentColor) private var accentColor

    let value: T
    let label: String
    var fontSize: CGFloat = 14
    var checkmarkSize: CGFloat = 12
    var textColor: Color = .primary
    var horizontalInsets: CGFloat = 8
    var verticalInsets: CGFloat = 6
    var itemCornerRadius: CGFloat = 2

    init(value: T, label: String) {
        self.value = value
        self.label = label
    }

    private var isSelected: Bool {
        selection?.isEqual(value) ?? false
    }

    var body: some View {
        Button(action: { onSelect?(value) }) {
            HStack(spacing: 0) {
                Text(label)
                    .font(.system(size: fontSize))
                    .foregroundColor(textColor)
                Spacer(minLength: 8)
                if isSelected {
                    SafeIcon("Check", size: checkmarkSize, color: textColor)
                }
            }
            .padding(.horizontal, horizontalInsets)
            .padding(.vertical, verticalInsets)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(SelectItemButtonStyle(isSelected: isSelected, accentColor: accentColor, cornerRadius: itemCornerRadius))
    }

    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func checkmarkSize(_ value: CGFloat) -> Self { configure { $0.checkmarkSize = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func horizontalInsets(_ value: CGFloat) -> Self { configure { $0.horizontalInsets = value } }
    func verticalInsets(_ value: CGFloat) -> Self { configure { $0.verticalInsets = value } }
    func itemCornerRadius(_ value: CGFloat) -> Self { configure { $0.itemCornerRadius = value } }
}

// MARK: - Select Item Button Style

struct SelectItemButtonStyle: ButtonStyle {
    var isSelected: Bool = false
    var accentColor: Color = SelectColors.accent
    var cornerRadius: CGFloat = 2

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                isSelected || configuration.isPressed
                    ? accentColor
                    : Color.clear
            )
            .cornerRadius(cornerRadius)
    }
}

// MARK: - Select Colors

enum SelectColors {
    static let accent = Color(hsl: 0, 0, 0.961)
}

// MARK: - Select Group

struct AppSelectGroup<Content: View>: View {
    let label: String?
    let content: Content
    var labelFontSize: CGFloat = 12
    var labelFontWeight: Font.Weight = .medium
    var labelColor: Color = .secondary
    var horizontalInsets: CGFloat = 8
    var verticalInsets: CGFloat = 6

    init(label: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let label {
                Text(label)
                    .font(.system(size: labelFontSize, weight: labelFontWeight))
                    .foregroundColor(labelColor)
                    .padding(.horizontal, horizontalInsets)
                    .padding(.vertical, verticalInsets)
            }
            content
        }
    }

    func labelFont(size: CGFloat, weight: Font.Weight = .medium) -> Self {
        configure { $0.labelFontSize = size; $0.labelFontWeight = weight }
    }

    func labelColor(_ value: Color) -> Self { configure { $0.labelColor = value } }
    func horizontalInsets(_ value: CGFloat) -> Self { configure { $0.horizontalInsets = value } }
    func verticalInsets(_ value: CGFloat) -> Self { configure { $0.verticalInsets = value } }
}

// MARK: - Select Separator

struct AppSelectSeparator: View {
    var verticalInsets: CGFloat = 4

    var body: some View {
        Divider()
            .padding(.vertical, verticalInsets)
    }

    func verticalInsets(_ value: CGFloat) -> Self { configure { $0.verticalInsets = value } }
}

// MARK: - Select Label

struct AppSelectLabel: View {
    let text: String
    var fontSize: CGFloat = 14
    var fontWeight: Font.Weight = .semibold
    var textColor: Color = .primary
    var horizontalInsets: CGFloat = 8
    var verticalInsets: CGFloat = 6

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundColor(textColor)
            .padding(.horizontal, horizontalInsets)
            .padding(.vertical, verticalInsets)
    }

    func font(size: CGFloat, weight: Font.Weight = .semibold) -> Self {
        configure { $0.fontSize = size; $0.fontWeight = weight }
    }

    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func horizontalInsets(_ value: CGFloat) -> Self { configure { $0.horizontalInsets = value } }
    func verticalInsets(_ value: CGFloat) -> Self { configure { $0.verticalInsets = value } }
}

// MARK: - Simple Select

struct AppSimpleSelect: View {
    @Binding var selection: String
    let options: [String]
    var placeholder: String = "Select..."

    init(selection: Binding<String>, options: [String], placeholder: String = "Select...") {
        _selection = selection
        self.options = options
        self.placeholder = placeholder
    }

    var body: some View {
        AppSelect(
            selection: $selection,
            displayValue: selection.isEmpty ? nil : selection
        ) {
            ForEach(options, id: \.self) { option in
                AppSelectItem(value: option, label: option)
            }
        }
        .placeholder(placeholder)
    }

    func placeholder(_ value: String) -> Self { configure { $0.placeholder = value } }
}
