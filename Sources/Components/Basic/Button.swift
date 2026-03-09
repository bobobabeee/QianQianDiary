import SwiftUI

// MARK: - Button Variant

enum ButtonVariant {
    case `default`
    case destructive
    case outline
    case secondary
    case ghost
    case link
}

// MARK: - Button Size

enum ButtonSize {
    case `default`
    case small
    case large
    case icon
}

// MARK: - Button

struct AppButton: View {
    let action: () -> Void
    let content: () -> AnyView
    var variant: ButtonVariant = .default
    var size: ButtonSize = .default
    var isEnabled: Bool = true
    var customBackgroundColor: Color? = nil
    var customForegroundColor: Color? = nil
    var cornerRadius: CGFloat = 24
    var background: AnyShapeStyle? = nil
    var customContentPadding: EdgeInsets? = nil
    var customTextFont: Font? = nil
    var customFixedHeight: CGFloat? = nil
    var isFullWidth: Bool = false

    init(action: @escaping () -> Void, @ViewBuilder content: @escaping () -> some View) {
        self.action = action
        self.content = { AnyView(content()) }
    }

    var body: some View {
        let resolvedHeight = customFixedHeight ?? fixedHeight

        Button(action: action) {
            HStack(spacing: 8) {
                content()
            }
            .font(customTextFont ?? textFont)
            .padding(contentPadding)
            .frame(
                minWidth: size == .icon ? resolvedHeight : nil,
                maxWidth: isFullWidth ? .infinity : (size == .icon ? resolvedHeight : nil),
                minHeight: resolvedHeight,
                maxHeight: resolvedHeight
            )
        }
        .buttonStyle(AppButtonStyle(
            variant: variant,
            size: size,
            isEnabled: isEnabled,
            customBackgroundColor: customBackgroundColor,
            customForegroundColor: customForegroundColor,
            cornerRadius: cornerRadius,
            background: background
        ))
        .disabled(!isEnabled)
    }

    private var textFont: Font {
        switch size {
        case .small:
            return .system(size: 12, weight: .medium)
        default:
            return .system(size: 14, weight: .medium)
        }
    }

    private var contentPadding: EdgeInsets {
        if let customContentPadding {
            return customContentPadding
        }
        switch size {
        case .small:
            return EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        case .large:
            return EdgeInsets(top: 0, leading: 28, bottom: 0, trailing: 28)
        case .icon:
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        case .default:
            return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        }
    }

    private var fixedHeight: CGFloat {
        switch size {
        case .small: 36
        case .large: 48
        case .icon, .default: 40
        }
    }

    // MARK: - Chain Methods

    func variant(_ value: ButtonVariant) -> Self { configure { $0.variant = value } }
    func size(_ value: ButtonSize) -> Self { configure { $0.size = value } }
    func disabled(_ value: Bool) -> Self { configure { $0.isEnabled = !value } }
    func backgroundColor(_ value: Color) -> Self { configure { $0.customBackgroundColor = value } }
    func foregroundColor(_ value: Color) -> Self { configure { $0.customForegroundColor = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func contentPadding(_ insets: EdgeInsets) -> Self { configure { $0.customContentPadding = insets } }
    func contentPadding(_ value: CGFloat) -> Self {
        configure { $0.customContentPadding = EdgeInsets(top: value, leading: value, bottom: value, trailing: value) }
    }
    func contentPadding(horizontal: CGFloat, vertical: CGFloat) -> Self {
        configure { $0.customContentPadding = EdgeInsets(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal) }
    }
    func font(_ value: Font) -> Self { configure { $0.customTextFont = value } }
    func font(size: CGFloat, weight: Font.Weight = .medium) -> Self {
        configure { $0.customTextFont = Font.system(size: size, weight: weight) }
    }
    func height(_ value: CGFloat) -> Self { configure { $0.customFixedHeight = value } }
    func fullWidth() -> Self { configure { $0.isFullWidth = true } }
}

// MARK: - Convenience Init

extension AppButton {
    init(_ title: String, action: @escaping () -> Void) {
        self.init(action: action) {
            Text(title)
        }
    }

    init(icon: String, action: @escaping () -> Void) {
        self.action = action
        content = {
            AnyView(
                SafeIcon(icon, size: 16)
            )
        }
        size = .icon
    }
}

// MARK: - Button Style

struct AppButtonStyle: ButtonStyle {
    let variant: ButtonVariant
    let size: ButtonSize
    let isEnabled: Bool
    let customBackgroundColor: Color?
    let customForegroundColor: Color?
    let cornerRadius: CGFloat
    let background: AnyShapeStyle?

    func makeBody(configuration: Configuration) -> some View {
        let backgroundStyle = background ?? AnyShapeStyle(backgroundColor(isPressed: configuration.isPressed))

        return Group {
            if variant == .link {
                configuration.label.underline()
            } else {
                configuration.label
            }
        }
        .background(backgroundStyle, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .foregroundColor(foregroundColor)
        .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(borderColor, lineWidth: variant == .outline ? 1 : 0))
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 1)
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if let customBackgroundColor {
            let bgColor = isPressed ? customBackgroundColor.opacity(0.9) : customBackgroundColor
            return isEnabled ? bgColor : bgColor.opacity(0.5)
        }
        
        let baseColor: Color
        switch variant {
        case .default:
            let primary = Color(hex: 0x3B82F6)
            baseColor = isPressed ? primary.opacity(0.9) : primary
        case .destructive:
            baseColor = isPressed ? Color.red.opacity(0.9) : Color.red
        case .outline:
            return isPressed ? Color.gray.opacity(0.1) : Color.clear
        case .secondary:
            baseColor = isPressed ? Color.secondary.opacity(0.8) : Color.secondary
        case .ghost:
            return isPressed ? Color.gray.opacity(0.1) : Color.clear
        case .link:
            return Color.clear
        }
        return isEnabled ? baseColor : baseColor.opacity(0.5)
    }

    private var foregroundColor: Color {
        if let customForegroundColor {
            return isEnabled ? customForegroundColor : customForegroundColor.opacity(0.5)
        }
        let baseColor: Color = switch variant {
        case .default, .destructive, .secondary:
            .white
        case .outline, .ghost:
            .primary
        case .link:
            Color(hex: 0x3B82F6)
        }
        return isEnabled ? baseColor : baseColor.opacity(0.5)
    }

    private var borderColor: Color {
        if variant == .outline {
            let baseColor = Color.gray.opacity(0.3)
            return isEnabled ? baseColor : baseColor.opacity(0.5)
        }
        return Color.clear
    }

    private var shadowColor: Color {
        if variant == .ghost || variant == .link {
            return Color.clear
        }
        let baseColor = Color.black.opacity(0.1)
        return isEnabled ? baseColor : baseColor.opacity(0.5)
    }

    private var shadowRadius: CGFloat {
        variant == .ghost || variant == .link ? 0 : 2
    }
}
