import SwiftUI

// MARK: - Badge Variant

enum BadgeVariant {
    case `default`
    case secondary
    case destructive
    case outline
}

// MARK: - Badge

struct AppBadge<Content: View>: View {
    let content: Content
    var variant: BadgeVariant = .default
    var fontSize: CGFloat = 12
    var fontWeight: Font.Weight = .semibold
    var horizontalPadding: CGFloat = 10
    var verticalPadding: CGFloat = 2
    var cornerRadius: CGFloat = 6
    var spacing: CGFloat = 4
    var customBackground: AnyShapeStyle?
    var customTextColor: Color?
    var customBorderColor: Color?

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: spacing) {
            content
        }
        .font(.system(size: fontSize, weight: fontWeight))
        .foregroundColor(computedTextColor)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(computedBackground)
        .cornerRadius(cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(computedBorderColor, lineWidth: hasBorder ? 1 : 0)
        )
        .shadow(
            color: hasShadow ? .black.opacity(0.1) : .clear,
            radius: hasShadow ? 2 : 0,
            x: 0,
            y: hasShadow ? 1 : 0
        )
    }

    private var computedBackground: AnyShapeStyle {
        if let custom = customBackground { return custom }
        switch variant {
        case .default: return AnyShapeStyle(Color.accentColor)
        case .secondary: return AnyShapeStyle(Color(UIColor.secondarySystemBackground))
        case .destructive: return AnyShapeStyle(Color.red)
        case .outline: return AnyShapeStyle(Color.clear)
        }
    }

    private var computedTextColor: Color {
        if let custom = customTextColor { return custom }
        switch variant {
        case .default, .destructive: return .white
        case .secondary, .outline: return .primary
        }
    }

    private var computedBorderColor: Color {
        if let custom = customBorderColor { return custom }
        return variant == .outline ? Color.gray.opacity(0.3) : .clear
    }

    private var hasBorder: Bool { variant == .outline || customBorderColor != nil }
    private var hasShadow: Bool { variant == .default || variant == .destructive }

    // MARK: - Chain Methods

    func variant(_ value: BadgeVariant) -> Self { configure { $0.variant = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.customBackground = AnyShapeStyle(style) } }
    func textColor(_ value: Color) -> Self { configure { $0.customTextColor = value } }
    func borderColor(_ value: Color) -> Self { configure { $0.customBorderColor = value } }

    func font(size: CGFloat, weight: Font.Weight = .semibold) -> Self {
        configure { $0.fontSize = size; $0.fontWeight = weight }
    }

    func padding(horizontal: CGFloat, vertical: CGFloat) -> Self {
        configure { $0.horizontalPadding = horizontal; $0.verticalPadding = vertical }
    }
}

// MARK: - Convenience

extension AppBadge where Content == Text {
    init(_ text: String) {
        content = Text(text)
    }

    static func `default`(_ text: String) -> AppBadge { AppBadge(text).variant(.default) }
    static func secondary(_ text: String) -> AppBadge { AppBadge(text).variant(.secondary) }
    static func destructive(_ text: String) -> AppBadge { AppBadge(text).variant(.destructive) }
    static func outline(_ text: String) -> AppBadge { AppBadge(text).variant(.outline) }

    static func count(_ number: Int) -> AppBadge {
        let text = number > 99 ? "99+" : "\(number)"
        return AppBadge(text).variant(.destructive)
    }
}

// MARK: - Badge With Icon

struct AppBadgeWithIcon: View {
    let icon: String
    let text: String?
    var variant: BadgeVariant = .default
    var iconSize: CGFloat = 12

    init(icon: String, text: String? = nil) {
        self.icon = icon
        self.text = text
    }

    var body: some View {
        AppBadge {
            SafeIcon(icon, size: iconSize)
            if let text { Text(text) }
        }
        .variant(variant)
    }

    func variant(_ value: BadgeVariant) -> Self { configure { $0.variant = value } }
    func iconSize(_ value: CGFloat) -> Self { configure { $0.iconSize = value } }
}
