import SwiftUI

// MARK: - Dialog

struct AppDialog<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    var overlayColor: Color = .black.opacity(0.8)
    var background: AnyShapeStyle = AnyShapeStyle(Color(UIColor.systemBackground))
    var cornerRadius: CGFloat = 8
    var maxWidth: CGFloat = 512
    var horizontalMargin: CGFloat = 16
    var padding: CGFloat = 24
    var shadowColor: Color = .black.opacity(0.2)
    var shadowRadius: CGFloat = 20
    var closeIconSize: CGFloat = 16

    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        _isPresented = isPresented
        self.content = content()
    }

    private var computedMaxWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return min(maxWidth, screenWidth - horizontalMargin * 2)
    }

    var body: some View {
        ZStack {
            if isPresented {
                overlayColor
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { isPresented = false }
                    }
                    .zIndex(0)

                dialogContent
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }

    @ViewBuilder
    private var dialogContent: some View {
        VStack(spacing: 16) {
            content
        }
        .padding(padding)
        .frame(maxWidth: computedMaxWidth)
        .background(background)
        .cornerRadius(cornerRadius)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 10)
        .overlay(alignment: .topTrailing) {
            Button(action: {
                withAnimation { isPresented = false }
            }) {
                SafeIcon("X", size: closeIconSize, color: .primary.opacity(0.7))
                    .padding(8)
            }
            .padding(8)
        }
    }

    // MARK: - Chain Methods

    func overlayColor(_ value: Color) -> Self { configure { $0.overlayColor = value } }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func maxWidth(_ value: CGFloat) -> Self { configure { $0.maxWidth = value } }
    func padding(_ value: CGFloat) -> Self { configure { $0.padding = value } }
    func closeIconSize(_ value: CGFloat) -> Self { configure { $0.closeIconSize = value } }

    func shadow(color: Color = .black.opacity(0.2), radius: CGFloat) -> Self {
        configure { $0.shadowColor = color; $0.shadowRadius = radius }
    }
}

// MARK: - Dialog Header

struct AppDialogHeader<Content: View>: View {
    let content: Content
    var spacing: CGFloat = 6

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
}

extension AppDialogHeader where Content == EmptyView {
    init() {
        self.content = EmptyView()
    }
}

// MARK: - Dialog Title

struct AppDialogTitle: View {
    let text: String
    var fontSize: CGFloat = 18
    var fontWeight: Font.Weight = .semibold
    var textColor: Color = .primary

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundColor(textColor)
            .lineSpacing(0)
    }

    func font(size: CGFloat, weight: Font.Weight = .semibold) -> Self {
        configure { $0.fontSize = size; $0.fontWeight = weight }
    }

    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
}

// MARK: - Dialog Description

struct AppDialogDescription: View {
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

// MARK: - Dialog Footer

struct AppDialogFooter<Content: View>: View {
    let content: Content
    var spacing: CGFloat = 8

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: spacing) {
            Spacer()
            content
        }
    }

    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
}

extension AppDialogFooter where Content == EmptyView {
    init() {
        self.content = EmptyView()
    }
}
