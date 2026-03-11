import Popovers
import SwiftUI

// MARK: - Menubar

struct AppMenubar<Content: View>: View {
    let content: Content
    var spacing: CGFloat = 4
    var contentInsets: CGFloat = 4
    var height: CGFloat = 36
    var background: AnyShapeStyle = AnyShapeStyle(Color(UIColor.systemBackground))
    var cornerRadius: CGFloat = 6
    var borderColor: Color = .gray.opacity(0.2)
    var shadowColor: Color = .black.opacity(0.05)
    var shadowRadius: CGFloat = 1

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: spacing) { content }
            .padding(contentInsets)
            .frame(height: height)
            .fixedSize(horizontal: true, vertical: false)
            .background(background)
            .cornerRadius(cornerRadius)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 1)
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(borderColor, lineWidth: 1))
    }

    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
    func contentInsets(_ value: CGFloat) -> Self { configure { $0.contentInsets = value } }
    func height(_ value: CGFloat) -> Self { configure { $0.height = value } }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }
    func shadowColor(_ value: Color) -> Self { configure { $0.shadowColor = value } }
    func shadowRadius(_ value: CGFloat) -> Self { configure { $0.shadowRadius = value } }
}

// MARK: - MenubarMenu

struct AppMenubarMenu<Content: View>: View {
    @State private var isExpanded: Bool = false
    let title: String
    let content: Content
    var minWidth: CGFloat = 192
    var maxHeight: CGFloat = 300
    var fontSize: CGFloat = 14
    var fontWeight: Font.Weight = .medium
    var accentColor: Color = Color(hsl: 0, 0, 0.961)
    var horizontalInsets: CGFloat = 12
    var verticalInsets: CGFloat = 4
    var itemCornerRadius: CGFloat = 3
    var popoverOffset: CGFloat = 8

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        Button(action: { isExpanded.toggle() }) {
            Text(title)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(.primary)
                .padding(.horizontal, horizontalInsets)
                .padding(.vertical, verticalInsets)
                .contentShape(Rectangle())
                .background(isExpanded ? accentColor : Color.clear)
                .cornerRadius(itemCornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
        .appPopover(
            isPresented: $isExpanded,
            side: .auto,
            sideOffset: popoverOffset
        ) {
            AppMenuContent(minWidth: minWidth, maxHeight: maxHeight) {
                content
            }
            .environment(\.menuDismiss) { isExpanded = false }
        }
    }

    func minWidth(_ value: CGFloat) -> Self { configure { $0.minWidth = value } }
    func maxHeight(_ value: CGFloat) -> Self { configure { $0.maxHeight = value } }
    func font(size: CGFloat, weight: Font.Weight = .medium) -> Self {
        configure { $0.fontSize = size; $0.fontWeight = weight }
    }
    func accentColor(_ value: Color) -> Self { configure { $0.accentColor = value } }
    func horizontalInsets(_ value: CGFloat) -> Self { configure { $0.horizontalInsets = value } }
    func verticalInsets(_ value: CGFloat) -> Self { configure { $0.verticalInsets = value } }
    func itemCornerRadius(_ value: CGFloat) -> Self { configure { $0.itemCornerRadius = value } }
    func popoverOffset(_ value: CGFloat) -> Self { configure { $0.popoverOffset = value } }
}

// MARK: - Type Aliases for Menubar

typealias AppMenubarItem = AppMenuItem
typealias AppMenubarSubMenu = AppMenuSubMenu
typealias AppMenubarCheckboxItem = AppMenuCheckboxItem
typealias AppMenubarRadioGroup = AppMenuRadioGroup
typealias AppMenubarRadioItem = AppMenuRadioItem
typealias AppMenubarLabel = AppMenuLabel
typealias AppMenubarSeparator = AppMenuSeparator
typealias AppMenubarShortcut = AppMenuShortcut
