import Popovers
import SwiftUI

// MARK: - Environment Keys

private struct MenuDismissKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

private struct MenuRadioSelectionKey: EnvironmentKey {
    static let defaultValue: AnyHashable? = nil
}

private struct MenuRadioOnSelectKey: EnvironmentKey {
    static let defaultValue: ((AnyHashable) -> Void)? = nil
}

extension EnvironmentValues {
    var menuDismiss: (() -> Void)? {
        get { self[MenuDismissKey.self] }
        set { self[MenuDismissKey.self] = newValue }
    }

    var menuRadioSelection: AnyHashable? {
        get { self[MenuRadioSelectionKey.self] }
        set { self[MenuRadioSelectionKey.self] = newValue }
    }

    var menuRadioOnSelect: ((AnyHashable) -> Void)? {
        get { self[MenuRadioOnSelectKey.self] }
        set { self[MenuRadioOnSelectKey.self] = newValue }
    }
}

// MARK: - Menu Content View

struct AppMenuContent<Content: View>: View {
    let content: Content
    var minWidth: CGFloat = 192
    var maxHeight: CGFloat = 300
    var contentInsets: CGFloat = 4
    var cornerRadius: CGFloat = 6
    var background: AnyShapeStyle = AnyShapeStyle(Color(UIColor.systemBackground))
    var borderColor: Color = .gray.opacity(0.2)
    var shadowColor: Color = .black.opacity(0.1)
    var shadowRadius: CGFloat = 6

    init(minWidth: CGFloat = 192, maxHeight: CGFloat = 300, @ViewBuilder content: () -> Content) {
        self.minWidth = minWidth
        self.maxHeight = maxHeight
        self.content = content()
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .frame(minWidth: minWidth)
        }
        .frame(maxHeight: maxHeight)
        .fixedSize(horizontal: true, vertical: true)
        .padding(contentInsets)
        .background(background)
        .cornerRadius(cornerRadius)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    func contentInsets(_ value: CGFloat) -> Self { configure { $0.contentInsets = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }
    func shadowColor(_ value: Color) -> Self { configure { $0.shadowColor = value } }
    func shadowRadius(_ value: CGFloat) -> Self { configure { $0.shadowRadius = value } }
}

// MARK: - MenuItem

struct AppMenuItem: View {
    @Environment(\.menuDismiss) private var dismiss

    let title: String
    let icon: String?
    let shortcut: String?
    let action: () -> Void
    var inset: Bool = false
    var disabled: Bool = false
    var fontSize: CGFloat = 14
    var iconSize: CGFloat = 14
    var shortcutFontSize: CGFloat = 12
    var textColor: Color = .primary
    var accentColor: Color = Color(hsl: 0, 0, 0.961)
    var horizontalInsets: CGFloat = 8
    var verticalInsets: CGFloat = 6
    var iconWidth: CGFloat = 16
    var itemCornerRadius: CGFloat = 3

    init(_ title: String, icon: String? = nil, shortcut: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.shortcut = shortcut
        self.action = action
    }

    var body: some View {
        Button(action: {
            guard !disabled else { return }
            action()
            dismiss?()
        }) {
            HStack(spacing: 8) {
                if let icon {
                    SafeIcon(icon, size: iconSize, color: textColor)
                        .frame(width: iconWidth)
                } else if inset {
                    Color.clear.frame(width: iconWidth)
                }
                Text(title)
                    .font(.system(size: fontSize))
                    .foregroundColor(textColor)
                Spacer(minLength: 16)
                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: shortcutFontSize))
                        .tracking(2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, horizontalInsets)
            .padding(.vertical, verticalInsets)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuItemButtonStyle(accentColor: accentColor, cornerRadius: itemCornerRadius))
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }

    func inset(_ value: Bool = true) -> Self { configure { $0.inset = value } }
    func disabled(_ value: Bool = true) -> Self { configure { $0.disabled = value } }
    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func iconSize(_ value: CGFloat) -> Self { configure { $0.iconSize = value } }
    func shortcutFontSize(_ value: CGFloat) -> Self { configure { $0.shortcutFontSize = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func accentColor(_ value: Color) -> Self { configure { $0.accentColor = value } }
    func horizontalInsets(_ value: CGFloat) -> Self { configure { $0.horizontalInsets = value } }
    func verticalInsets(_ value: CGFloat) -> Self { configure { $0.verticalInsets = value } }
    func iconWidth(_ value: CGFloat) -> Self { configure { $0.iconWidth = value } }
    func itemCornerRadius(_ value: CGFloat) -> Self { configure { $0.itemCornerRadius = value } }
}

// MARK: - MenuSubMenu

struct AppMenuSubMenu<Content: View>: View {
    @Environment(\.menuDismiss) private var parentDismiss
    @State private var isExpanded: Bool = false

    let title: String
    let icon: String?
    let content: Content
    var inset: Bool = false
    var fontSize: CGFloat = 14
    var iconSize: CGFloat = 14
    var textColor: Color = .primary
    var accentColor: Color = Color(hsl: 0, 0, 0.961)
    var minWidth: CGFloat = 128
    var maxHeight: CGFloat = 300
    var horizontalInsets: CGFloat = 8
    var verticalInsets: CGFloat = 6
    var iconWidth: CGFloat = 16
    var itemCornerRadius: CGFloat = 3

    init(_ title: String, icon: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        Button(action: { isExpanded.toggle() }) {
            HStack(spacing: 8) {
                if let icon {
                    SafeIcon(icon, size: iconSize, color: textColor)
                        .frame(width: iconWidth)
                } else if inset {
                    Color.clear.frame(width: iconWidth)
                }
                Text(title)
                    .font(.system(size: fontSize))
                    .foregroundColor(textColor)
                Spacer(minLength: 16)
                SafeIcon("ChevronRight", size: iconSize, color: .secondary)
            }
            .padding(.horizontal, horizontalInsets)
            .padding(.vertical, verticalInsets)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuItemButtonStyle(accentColor: accentColor, cornerRadius: itemCornerRadius))
        .appPopover(
            isPresented: $isExpanded,
            side: .right,
            sideOffset: 0
        ) {
            AppMenuContent(minWidth: minWidth, maxHeight: maxHeight) {
                content
            }
            .environment(\.menuDismiss) {
                isExpanded = false
                parentDismiss?()
            }
        }
    }

    func inset(_ value: Bool = true) -> Self { configure { $0.inset = value } }
    func minWidth(_ value: CGFloat) -> Self { configure { $0.minWidth = value } }
    func maxHeight(_ value: CGFloat) -> Self { configure { $0.maxHeight = value } }
    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func iconSize(_ value: CGFloat) -> Self { configure { $0.iconSize = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func accentColor(_ value: Color) -> Self { configure { $0.accentColor = value } }
    func horizontalInsets(_ value: CGFloat) -> Self { configure { $0.horizontalInsets = value } }
    func verticalInsets(_ value: CGFloat) -> Self { configure { $0.verticalInsets = value } }
    func iconWidth(_ value: CGFloat) -> Self { configure { $0.iconWidth = value } }
    func itemCornerRadius(_ value: CGFloat) -> Self { configure { $0.itemCornerRadius = value } }
}

// MARK: - MenuCheckboxItem

struct AppMenuCheckboxItem: View {
    @Environment(\.menuDismiss) private var dismiss

    let title: String
    @Binding var isChecked: Bool
    var disabled: Bool = false
    var fontSize: CGFloat = 14
    var checkmarkSize: CGFloat = 14
    var textColor: Color = .primary
    var accentColor: Color = Color(hsl: 0, 0, 0.961)
    var indicatorWidth: CGFloat = 32
    var verticalInsets: CGFloat = 6
    var itemCornerRadius: CGFloat = 3

    init(_ title: String, isChecked: Binding<Bool>) {
        self.title = title
        _isChecked = isChecked
    }

    var body: some View {
        Button(action: {
            guard !disabled else { return }
            isChecked.toggle()
            dismiss?()
        }) {
            HStack(spacing: 0) {
                SafeIcon("Check", size: checkmarkSize, color: textColor)
                    .frame(width: indicatorWidth, alignment: .center)
                    .opacity(isChecked ? 1 : 0)
                Text(title)
                    .font(.system(size: fontSize))
                    .foregroundColor(textColor)
                Spacer()
            }
            .padding(.trailing, 8)
            .padding(.vertical, verticalInsets)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuItemButtonStyle(accentColor: accentColor, cornerRadius: itemCornerRadius))
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }

    func disabled(_ value: Bool = true) -> Self { configure { $0.disabled = value } }
    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func checkmarkSize(_ value: CGFloat) -> Self { configure { $0.checkmarkSize = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func accentColor(_ value: Color) -> Self { configure { $0.accentColor = value } }
    func indicatorWidth(_ value: CGFloat) -> Self { configure { $0.indicatorWidth = value } }
    func verticalInsets(_ value: CGFloat) -> Self { configure { $0.verticalInsets = value } }
    func itemCornerRadius(_ value: CGFloat) -> Self { configure { $0.itemCornerRadius = value } }
}

// MARK: - MenuRadioGroup

struct AppMenuRadioGroup<T: Hashable, Content: View>: View {
    @Binding var selection: T
    let content: Content

    init(selection: Binding<T>, @ViewBuilder content: () -> Content) {
        _selection = selection
        self.content = content()
    }

    var body: some View {
        content
            .environment(\.menuRadioSelection, AnyHashable(selection))
            .environment(\.menuRadioOnSelect) { value in
                if let typedValue = value as? T {
                    selection = typedValue
                }
            }
    }
}

// MARK: - MenuRadioItem

struct AppMenuRadioItem<T: Hashable>: View {
    @Environment(\.menuDismiss) private var dismiss
    @Environment(\.menuRadioSelection) private var selection
    @Environment(\.menuRadioOnSelect) private var onSelect

    let title: String
    let value: T
    var disabled: Bool = false
    var fontSize: CGFloat = 14
    var indicatorSize: CGFloat = 8
    var textColor: Color = .primary
    var accentColor: Color = Color(hsl: 0, 0, 0.961)
    var indicatorWidth: CGFloat = 32
    var verticalInsets: CGFloat = 6
    var itemCornerRadius: CGFloat = 3

    init(_ title: String, value: T) {
        self.title = title
        self.value = value
    }

    private var isSelected: Bool {
        selection == AnyHashable(value)
    }

    var body: some View {
        Button(action: {
            guard !disabled else { return }
            onSelect?(AnyHashable(value))
            dismiss?()
        }) {
            HStack(spacing: 0) {
                SafeIcon("Circle", size: indicatorSize, color: textColor)
                    .frame(width: indicatorWidth, alignment: .center)
                    .opacity(isSelected ? 1 : 0)
                Text(title)
                    .font(.system(size: fontSize))
                    .foregroundColor(textColor)
                Spacer()
            }
            .padding(.trailing, 8)
            .padding(.vertical, verticalInsets)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuItemButtonStyle(accentColor: accentColor, cornerRadius: itemCornerRadius))
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }

    func disabled(_ value: Bool = true) -> Self { configure { $0.disabled = value } }
    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func indicatorSize(_ value: CGFloat) -> Self { configure { $0.indicatorSize = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func accentColor(_ value: Color) -> Self { configure { $0.accentColor = value } }
    func indicatorWidth(_ value: CGFloat) -> Self { configure { $0.indicatorWidth = value } }
    func verticalInsets(_ value: CGFloat) -> Self { configure { $0.verticalInsets = value } }
    func itemCornerRadius(_ value: CGFloat) -> Self { configure { $0.itemCornerRadius = value } }
}

// MARK: - MenuLabel

struct AppMenuLabel: View {
    let text: String
    var inset: Bool = false
    var fontSize: CGFloat = 14
    var fontWeight: Font.Weight = .semibold
    var textColor: Color = .primary
    var indicatorWidth: CGFloat = 32
    var horizontalInsets: CGFloat = 8
    var verticalInsets: CGFloat = 6

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(spacing: 0) {
            if inset {
                Color.clear.frame(width: indicatorWidth)
            }
            Text(text)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(textColor)
        }
        .padding(.horizontal, inset ? 0 : horizontalInsets)
        .padding(.trailing, inset ? horizontalInsets : 0)
        .padding(.vertical, verticalInsets)
    }

    func inset(_ value: Bool = true) -> Self { configure { $0.inset = value } }
    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func fontWeight(_ value: Font.Weight) -> Self { configure { $0.fontWeight = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func indicatorWidth(_ value: CGFloat) -> Self { configure { $0.indicatorWidth = value } }
    func horizontalInsets(_ value: CGFloat) -> Self { configure { $0.horizontalInsets = value } }
    func verticalInsets(_ value: CGFloat) -> Self { configure { $0.verticalInsets = value } }
}

// MARK: - MenuSeparator

struct AppMenuSeparator: View {
    var horizontalInsets: CGFloat = -4
    var verticalInsets: CGFloat = 4

    var body: some View {
        Divider()
            .padding(.horizontal, horizontalInsets)
            .padding(.vertical, verticalInsets)
    }

    func horizontalInsets(_ value: CGFloat) -> Self { configure { $0.horizontalInsets = value } }
    func verticalInsets(_ value: CGFloat) -> Self { configure { $0.verticalInsets = value } }
}

// MARK: - MenuShortcut

struct AppMenuShortcut: View {
    let text: String
    var fontSize: CGFloat = 12
    var tracking: CGFloat = 2
    var textColor: Color = .secondary

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .tracking(tracking)
            .foregroundColor(textColor)
    }

    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func tracking(_ value: CGFloat) -> Self { configure { $0.tracking = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
}

// MARK: - Menu Item Button Style

struct MenuItemButtonStyle: ButtonStyle {
    var accentColor: Color
    var cornerRadius: CGFloat = 3

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? accentColor : Color.clear)
            .cornerRadius(cornerRadius)
    }
}
