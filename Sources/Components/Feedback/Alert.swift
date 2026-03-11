import SwiftUI

// MARK: - Alert Variant

enum AlertVariant {
    case `default`
    case destructive
}

// MARK: - Alert

struct AppAlert<Content: View>: View {
    let content: Content
    var variant: AlertVariant = .default
    var cornerRadius: CGFloat = 8
    var horizontalPadding: CGFloat = 16
    var verticalPadding: CGFloat = 12
    var background: AnyShapeStyle?
    var borderColor: Color?

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(computedBackground)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(computedBorderColor, lineWidth: 1)
            )
    }

    private var computedBackground: AnyShapeStyle {
        if let bg = background { return bg }
        switch variant {
        case .default: return AnyShapeStyle(Color(.systemBackground))
        case .destructive: return AnyShapeStyle(Color.red.opacity(0.05))
        }
    }

    private var computedBorderColor: Color {
        if let border = borderColor { return border }
        switch variant {
        case .default: return Color.gray.opacity(0.2)
        case .destructive: return Color.red.opacity(0.5)
        }
    }

    // MARK: - Chain Methods

    func variant(_ value: AlertVariant) -> Self { configure { $0.variant = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }

    func padding(horizontal: CGFloat, vertical: CGFloat) -> Self {
        configure { $0.horizontalPadding = horizontal; $0.verticalPadding = vertical }
    }
}

// MARK: - Alert Title

struct AppAlertTitle: View {
    let text: String
    var variant: AlertVariant = .default
    var fontSize: CGFloat = 14
    var fontWeight: Font.Weight = .medium
    var textColor: Color?

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundColor(computedTextColor)
            .lineSpacing(0)
    }

    private var computedTextColor: Color {
        if let color = textColor { return color }
        switch variant {
        case .default: return .primary
        case .destructive: return .red
        }
    }

    func variant(_ value: AlertVariant) -> Self { configure { $0.variant = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }

    func font(size: CGFloat, weight: Font.Weight = .medium) -> Self {
        configure { $0.fontSize = size; $0.fontWeight = weight }
    }
}

// MARK: - Alert Description

struct AppAlertDescription: View {
    let text: String
    var fontSize: CGFloat = 14
    var textColor: Color = .secondary

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .foregroundColor(textColor)
    }

    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
}

// MARK: - Convenience Init

extension AppAlert where Content == AnyView {
    init(title: String, description: String? = nil) {
        content = AnyView(
            VStack(alignment: .leading, spacing: description != nil ? 4 : 0) {
                AppAlertTitle(title)
                if let desc = description {
                    AppAlertDescription(desc)
                }
            }
        )
    }

    init(title: String, icon: String, description: String? = nil, iconColor: Color? = nil) {
        let computedIconColor = iconColor ?? .blue
        content = AnyView(
            AlertIconContent(
                title: title,
                icon: icon,
                description: description,
                iconColor: computedIconColor
            )
        )
    }
}

// MARK: - Alert Icon Content

private struct AlertIconContent: View {
    let title: String
    let icon: String
    let description: String?
    let iconColor: Color

    var body: some View {
        HStack(alignment: description != nil ? .top : .center, spacing: 12) {
            SafeIcon(icon, size: 16, color: iconColor)

            VStack(alignment: .leading, spacing: description != nil ? 4 : 0) {
                AppAlertTitle(title)
                if let desc = description {
                    AppAlertDescription(desc)
                }
            }
        }
    }
}
