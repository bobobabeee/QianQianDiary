import Popovers
import SwiftUI

// MARK: - Environment Key

private struct NavigationMenuDismissKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var navigationMenuDismiss: (() -> Void)? {
        get { self[NavigationMenuDismissKey.self] }
        set { self[NavigationMenuDismissKey.self] = newValue }
    }
}

// MARK: - NavigationMenu

struct AppNavigationMenu<Content: View>: View {
    let content: Content
    var spacing: CGFloat = 4

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: spacing) { content }
    }

    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
}

// MARK: - NavigationMenuList

struct AppNavigationMenuList<Content: View>: View {
    let content: Content
    var spacing: CGFloat = 4

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: spacing) { content }
    }

    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
}

// MARK: - NavigationMenuItem

struct AppNavigationMenuItem<MenuContent: View>: View {
    @State private var isExpanded: Bool = false
    let title: String
    let menuContent: MenuContent
    var fontSize: CGFloat = 14
    var fontWeight: Font.Weight = .medium
    var chevronSize: CGFloat = 12
    var triggerHeight: CGFloat = 36
    var horizontalInsets: CGFloat = 16
    var itemSpacing: CGFloat = 4
    var cornerRadius: CGFloat = 6
    var accentColor: Color = Color(hsl: 0, 0, 0.961)
    var minWidth: CGFloat = 200
    var contentInsets: CGFloat = 4
    var shadowColor: Color = .black.opacity(0.15)
    var shadowRadius: CGFloat = 8
    var borderColor: Color = .gray.opacity(0.2)

    init(_ title: String, @ViewBuilder menuContent: () -> MenuContent) {
        self.title = title
        self.menuContent = menuContent()
    }

    var body: some View {
        Button(action: { isExpanded.toggle() }) {
            HStack(spacing: itemSpacing) {
                Text(title)
                    .font(.system(size: fontSize, weight: fontWeight))
                    .foregroundColor(.primary)
                SafeIcon("ChevronDown", size: chevronSize, color: .secondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(.easeInOut(duration: 0.3), value: isExpanded)
            }
            .padding(.horizontal, horizontalInsets)
            .frame(height: triggerHeight)
            .contentShape(Rectangle())
            .background(isExpanded ? accentColor : Color.clear)
            .cornerRadius(cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
        .appPopover(
            isPresented: $isExpanded,
            side: .auto,
            sideOffset: 6
        ) {
            VStack(alignment: .leading, spacing: 0) {
                menuContent
            }
            .frame(minWidth: minWidth)
            .padding(contentInsets)
            .background(Color(.systemBackground))
            .cornerRadius(cornerRadius)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .environment(\.navigationMenuDismiss) { isExpanded = false }
        }
    }

    func font(size: CGFloat, weight: Font.Weight = .medium) -> Self {
        configure { $0.fontSize = size; $0.fontWeight = weight }
    }

    func chevronSize(_ value: CGFloat) -> Self { configure { $0.chevronSize = value } }
    func triggerHeight(_ value: CGFloat) -> Self { configure { $0.triggerHeight = value } }
    func horizontalInsets(_ value: CGFloat) -> Self { configure { $0.horizontalInsets = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func accentColor(_ value: Color) -> Self { configure { $0.accentColor = value } }
    func minWidth(_ value: CGFloat) -> Self { configure { $0.minWidth = value } }
    func contentInsets(_ value: CGFloat) -> Self { configure { $0.contentInsets = value } }
    func shadowColor(_ value: Color) -> Self { configure { $0.shadowColor = value } }
    func shadowRadius(_ value: CGFloat) -> Self { configure { $0.shadowRadius = value } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }
}

// MARK: - NavigationMenuTrigger

struct AppNavigationMenuTrigger: View {
    let title: String
    let action: () -> Void
    var fontSize: CGFloat = 14
    var fontWeight: Font.Weight = .medium
    var height: CGFloat = 36
    var horizontalInsets: CGFloat = 16
    var accentColor: Color = Color(hsl: 0, 0, 0.961)
    var cornerRadius: CGFloat = 6

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(.primary)
                .padding(.horizontal, horizontalInsets)
                .frame(height: height)
                .contentShape(Rectangle())
        }
        .buttonStyle(NavigationMenuButtonStyle(accentColor: accentColor, cornerRadius: cornerRadius))
    }

    func font(size: CGFloat, weight: Font.Weight = .medium) -> Self {
        configure { $0.fontSize = size; $0.fontWeight = weight }
    }

    func height(_ value: CGFloat) -> Self { configure { $0.height = value } }
    func horizontalInsets(_ value: CGFloat) -> Self { configure { $0.horizontalInsets = value } }
    func accentColor(_ value: Color) -> Self { configure { $0.accentColor = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
}

// MARK: - NavigationMenuLink

struct AppNavigationMenuLink: View {
    @Environment(\.navigationMenuDismiss) private var dismiss

    let title: String
    let description: String?
    let action: () -> Void
    var fontSize: CGFloat = 14
    var descriptionFontSize: CGFloat = 12
    var textColor: Color = .primary
    var descriptionColor: Color = .secondary
    var accentColor: Color = Color(hsl: 0, 0, 0.961)
    var horizontalInsets: CGFloat = 12
    var verticalInsets: CGFloat = 8
    var itemCornerRadius: CGFloat = 4

    init(_ title: String, description: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.description = description
        self.action = action
    }

    var body: some View {
        Button(action: {
            action()
            dismiss?()
        }) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(textColor)
                if let description {
                    Text(description)
                        .font(.system(size: descriptionFontSize))
                        .foregroundColor(descriptionColor)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, horizontalInsets)
            .padding(.vertical, verticalInsets)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(NavigationMenuButtonStyle(accentColor: accentColor, cornerRadius: itemCornerRadius))
    }

    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func descriptionFontSize(_ value: CGFloat) -> Self { configure { $0.descriptionFontSize = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func descriptionColor(_ value: Color) -> Self { configure { $0.descriptionColor = value } }
    func accentColor(_ value: Color) -> Self { configure { $0.accentColor = value } }
    func horizontalInsets(_ value: CGFloat) -> Self { configure { $0.horizontalInsets = value } }
    func verticalInsets(_ value: CGFloat) -> Self { configure { $0.verticalInsets = value } }
    func itemCornerRadius(_ value: CGFloat) -> Self { configure { $0.itemCornerRadius = value } }
}

// MARK: - NavigationMenu Button Style

struct NavigationMenuButtonStyle: ButtonStyle {
    var accentColor: Color
    var cornerRadius: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? accentColor : Color.clear)
            .cornerRadius(cornerRadius)
    }
}
