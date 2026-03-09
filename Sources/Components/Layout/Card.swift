import SwiftUI

// MARK: - Card

struct AppCard<Content: View>: View {
    let content: Content
    var background: AnyShapeStyle = AnyShapeStyle(Color(UIColor.systemBackground))
    var borderColor: Color = .init(hex: 0xE5E7EB)
    var cornerRadius: CGFloat = 12
    var shadowRadius: CGFloat = 4
    var shadowColor: Color = .black.opacity(0.1)

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .background(background)
        .cornerRadius(cornerRadius)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Chain Methods

    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }

    func shadow(color: Color = .black.opacity(0.1), radius: CGFloat) -> Self {
        configure { $0.shadowColor = color; $0.shadowRadius = radius }
    }
}

// MARK: - Card Header

struct AppCardHeader<Content: View>: View {
    let content: Content
    var padding: CGFloat = 24
    var spacing: CGFloat = 6

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .padding(padding)
    }

    func padding(_ value: CGFloat) -> Self { configure { $0.padding = value } }
    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
}

extension AppCardHeader where Content == EmptyView {
    init() {
        self.content = EmptyView()
    }
}

// MARK: - Card Title

struct AppCardTitle<Content: View>: View {
    let content: Content
    var fontSize: CGFloat = 18
    var fontWeight: Font.Weight = .semibold
    var textColor: Color = .primary
    var spacing: CGFloat = 8

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            content
        }
        .font(.system(size: fontSize, weight: fontWeight))
        .foregroundColor(textColor)
    }

    func font(size: CGFloat, weight: Font.Weight = .semibold) -> Self {
        configure { $0.fontSize = size; $0.fontWeight = weight }
    }

    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
}

extension AppCardTitle where Content == AnyView {
    init(_ text: String) {
        self.init {
            AnyView(
                Text(text)
                    .kerning(-0.4)
            )
        }
    }
}

// MARK: - Card Description

struct AppCardDescription: View {
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

// MARK: - Card Content

struct AppCardContent<Content: View>: View {
    let content: Content
    var horizontalPadding: CGFloat = 24
    var bottomPadding: CGFloat = 24
    var topPadding: CGFloat = 0
    var spacing: CGFloat = 16

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .padding(.top, topPadding)
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, bottomPadding)
    }

    func padding(horizontal: CGFloat, bottom: CGFloat) -> Self {
        configure { $0.horizontalPadding = horizontal; $0.bottomPadding = bottom }
    }

    func padding(top: CGFloat = 0, horizontal: CGFloat, bottom: CGFloat) -> Self {
        configure { $0.topPadding = top; $0.horizontalPadding = horizontal; $0.bottomPadding = bottom }
    }

    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
}

// MARK: - Card Footer

struct AppCardFooter<Content: View>: View {
    let content: Content
    var horizontalPadding: CGFloat = 24
    var bottomPadding: CGFloat = 24

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack {
            content
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, bottomPadding)
    }

    func padding(horizontal: CGFloat, bottom: CGFloat) -> Self {
        configure { $0.horizontalPadding = horizontal; $0.bottomPadding = bottom }
    }
}

extension AppCardFooter where Content == EmptyView {
    init() {
        self.content = EmptyView()
    }
}
