import SwiftUI

// MARK: - Empty Media Variant

enum EmptyMediaVariant {
    case `default`
    case icon
}

// MARK: - Empty

struct AppEmpty<Content: View>: View {
    let content: Content
    var spacing: CGFloat = 24
    var padding: CGFloat = 24
    var borderColor: Color = .gray.opacity(0.3)
    var cornerRadius: CGFloat = 8
    var showBorder: Bool = true

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: spacing) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            Group {
                if showBorder {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundColor(borderColor)
                }
            }
        )
    }

    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
    func padding(_ value: CGFloat) -> Self { configure { $0.padding = value } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func showBorder(_ value: Bool) -> Self { configure { $0.showBorder = value } }
}

// MARK: - Empty Header

struct AppEmptyHeader<Content: View>: View {
    let content: Content
    var spacing: CGFloat = 8
    var preferredMaxWidth: CGFloat = 384
    var horizontalPadding: CGFloat = 32

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private var computedMaxWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return min(preferredMaxWidth, screenWidth - horizontalPadding * 2)
    }

    var body: some View {
        VStack(spacing: spacing) {
            content
        }
        .frame(maxWidth: computedMaxWidth)
        .multilineTextAlignment(.center)
    }

    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
    func preferredMaxWidth(_ value: CGFloat) -> Self { configure { $0.preferredMaxWidth = value } }
}

extension AppEmptyHeader where Content == EmptyView {
    init() {
        self.content = EmptyView()
    }
}

// MARK: - Empty Media

struct AppEmptyMedia<Content: View>: View {
    let content: Content
    var variant: EmptyMediaVariant = .default
    var iconSize: CGFloat = 40
    var iconCornerRadius: CGFloat = 8
    var iconBackgroundColor: Color = .init(UIColor.secondarySystemBackground)
    var iconColor: Color = .primary

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Group {
            switch variant {
            case .icon:
                ZStack {
                    RoundedRectangle(cornerRadius: iconCornerRadius)
                        .fill(iconBackgroundColor)
                        .frame(width: iconSize, height: iconSize)
                    content.foregroundColor(iconColor)
                }
            case .default:
                content
            }
        }
        .padding(.bottom, 8)
    }

    func variant(_ value: EmptyMediaVariant) -> Self { configure { $0.variant = value } }
    func iconSize(_ value: CGFloat) -> Self { configure { $0.iconSize = value } }
    func iconBackgroundColor(_ value: Color) -> Self { configure { $0.iconBackgroundColor = value } }
    func iconColor(_ value: Color) -> Self { configure { $0.iconColor = value } }
}

// MARK: - Empty Title

struct AppEmptyTitle: View {
    let text: String
    var fontSize: CGFloat = 18
    var fontWeight: Font.Weight = .medium
    var textColor: Color = .primary

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundColor(textColor)
            .multilineTextAlignment(.center)
    }

    func font(size: CGFloat, weight: Font.Weight = .medium) -> Self {
        configure { $0.fontSize = size; $0.fontWeight = weight }
    }

    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
}

// MARK: - Empty Description

struct AppEmptyDescription: View {
    let text: String
    var fontSize: CGFloat = 14
    var textColor: Color = .secondary
    var lineSpacing: CGFloat = 4

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .foregroundColor(textColor)
            .lineSpacing(lineSpacing)
            .multilineTextAlignment(.center)
    }

    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
}

// MARK: - Empty Content

struct AppEmptyContent<Content: View>: View {
    let content: Content
    var spacing: CGFloat = 16
    var preferredMaxWidth: CGFloat = 384
    var horizontalPadding: CGFloat = 32

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private var computedMaxWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return min(preferredMaxWidth, screenWidth - horizontalPadding * 2)
    }

    var body: some View {
        VStack(spacing: spacing) {
            content
        }
        .frame(maxWidth: computedMaxWidth)
    }

    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
    func preferredMaxWidth(_ value: CGFloat) -> Self { configure { $0.preferredMaxWidth = value } }
}

// MARK: - Convenience Empty State

struct AppEmptyState: View {
    var icon: String?
    var title: String
    var description: String?
    var actionTitle: String?
    var action: (() -> Void)?
    var iconVariant: EmptyMediaVariant = .icon
    var showBorder: Bool = true

    init(title: String) {
        self.title = title
    }

    var body: some View {
        AppEmpty {
            AppEmptyHeader {
                if let icon {
                    AppEmptyMedia {
                        SafeIcon(icon, size: 24)
                    }
                    .variant(iconVariant)
                }
                AppEmptyTitle(title)
                if let description {
                    AppEmptyDescription(description)
                }
            }

            if let actionTitle, let action {
                AppEmptyContent {
                    AppButton(action: action) { Text(actionTitle) }
                }
            }
        }
        .showBorder(showBorder)
    }

    func icon(_ value: String) -> Self { configure { $0.icon = value } }
    func description(_ value: String) -> Self { configure { $0.description = value } }

    func action(title: String, action: @escaping () -> Void) -> Self {
        configure { $0.actionTitle = title; $0.action = action }
    }

    func showBorder(_ value: Bool) -> Self { configure { $0.showBorder = value } }
}
