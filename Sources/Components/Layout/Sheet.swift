import SwiftUI

// MARK: - Sheet Side

enum SheetSide {
    case top
    case bottom
    case left
    case right
}

// MARK: - Sheet Configuration

struct SheetConfiguration {
    var side: SheetSide = .right
    var overlayColor: Color = .black.opacity(0.8)
    var background: AnyShapeStyle = AnyShapeStyle(Color(UIColor.systemBackground))
    var cornerRadius: CGFloat = 12
    var shadowRadius: CGFloat = 10
    var shadowColor: Color = .black.opacity(0.2)
    var closeIconSize: CGFloat = 16
}

// MARK: - Sheet Window Manager

private class SheetWindowManager {
    static let shared = SheetWindowManager()
    private var sheetWindow: UIWindow?

    func show(config: SheetConfiguration, content: some View, onDismiss: @escaping () -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }

        let window = UIWindow(windowScene: windowScene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear

        let hostingController = UIHostingController(rootView:
            SheetContainerView(config: config, content: content) {
                self.dismiss()
                onDismiss()
            }
        )
        hostingController.view.backgroundColor = .clear
        window.rootViewController = hostingController
        window.makeKeyAndVisible()

        sheetWindow = window
    }

    func dismiss() {
        sheetWindow?.isHidden = true
        sheetWindow = nil
    }
}

// MARK: - Sheet Container View

private struct SheetContainerView<Content: View>: View {
    let config: SheetConfiguration
    let content: Content
    let onDismiss: () -> Void

    @State private var showOverlay = false
    @State private var showContent = false

    var body: some View {
        ZStack {
            if showOverlay {
                config.overlayColor
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissSheet()
                    }
                    .transition(.opacity)
            }

            ZStack(alignment: alignment) {
                Color.clear
                if showContent {
                    sheetContentView
                        .transition(transitionForSide)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                showOverlay = true
            }
            withAnimation(.easeInOut(duration: 0.3).delay(0.05)) {
                showContent = true
            }
        }
    }

    private func dismissSheet() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showContent = false
        }
        withAnimation(.easeInOut(duration: 0.3).delay(0.1)) {
            showOverlay = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onDismiss()
        }
    }

    @ViewBuilder
    private var sheetContentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            closeButton
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            if isHorizontal {
                Spacer(minLength: 0)
            }
        }
        .frame(width: isHorizontal ? sheetWidth : nil)
        .frame(maxWidth: isHorizontal ? nil : .infinity)
        .frame(maxHeight: isHorizontal ? .infinity : nil)
        .background(config.background)
        .cornerRadius(config.cornerRadius, corners: cornersToRound)
        .shadow(color: config.shadowColor, radius: config.shadowRadius, x: 0, y: 0)
    }

    @ViewBuilder
    private var closeButton: some View {
        HStack {
            Spacer()
            Button(action: dismissSheet) {
                SafeIcon("X", size: config.closeIconSize, color: .secondary.opacity(0.7))
                    .padding(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, topPaddingForCloseButton)
    }

    private var topPaddingForCloseButton: CGFloat {
        guard needsTopSafeArea else { return 16 }
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
        let safeAreaTop = window?.safeAreaInsets.top ?? 0
        return max(safeAreaTop, 16)
    }

    private var needsTopSafeArea: Bool {
        config.side == .top || config.side == .left || config.side == .right
    }

    private var transitionForSide: AnyTransition {
        switch config.side {
        case .top: .move(edge: .top)
        case .bottom: .move(edge: .bottom)
        case .left: .move(edge: .leading)
        case .right: .move(edge: .trailing)
        }
    }

    private var isHorizontal: Bool { config.side == .left || config.side == .right }

    private var sheetWidth: CGFloat? {
        switch config.side {
        case .left, .right: min(UIScreen.main.bounds.width * 0.75, 384)
        case .top, .bottom: nil
        }
    }

    private var alignment: Alignment {
        switch config.side {
        case .top: .top
        case .bottom: .bottom
        case .left: .leading
        case .right: .trailing
        }
    }

    private var cornersToRound: UIRectCorner {
        switch config.side {
        case .top: [.bottomLeft, .bottomRight]
        case .bottom: [.topLeft, .topRight]
        case .left: [.topRight, .bottomRight]
        case .right: [.topLeft, .bottomLeft]
        }
    }
}

// MARK: - Sheet View Modifier

struct AppSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let sheetContent: SheetContent
    var config: SheetConfiguration

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { newValue in
                if newValue {
                    SheetWindowManager.shared.show(config: config, content: sheetContent) {
                        isPresented = false
                    }
                } else {
                    SheetWindowManager.shared.dismiss()
                }
            }
    }
}

// MARK: - View Extension

extension View {
    func appSheet(
        isPresented: Binding<Bool>,
        side: SheetSide = .right,
        overlayColor: Color = .black.opacity(0.8),
        background: AnyShapeStyle = AnyShapeStyle(Color(UIColor.systemBackground)),
        cornerRadius: CGFloat = 12,
        @ViewBuilder content: () -> some View
    ) -> some View {
        let config = SheetConfiguration(
            side: side,
            overlayColor: overlayColor,
            background: background,
            cornerRadius: cornerRadius
        )
        return modifier(AppSheetModifier(
            isPresented: isPresented,
            sheetContent: content(),
            config: config
        ))
    }
}

// MARK: - Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Sheet Header

struct AppSheetHeader<Content: View>: View {
    let content: Content
    var spacing: CGFloat = 8

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func spacing(_ value: CGFloat) -> Self {
        configure {
            $0.spacing = value
        }
    }
}

extension AppSheetHeader where Content == EmptyView {
    init() {
        self.content = EmptyView()
    }
}

// MARK: - Sheet Title

struct AppSheetTitle: View {
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
    }

    func font(size: CGFloat, weight: Font.Weight = .semibold) -> Self {
        configure {
            $0.fontSize = size
            $0.fontWeight = weight
        }
    }

    func textColor(_ value: Color) -> Self {
        configure {
            $0.textColor = value
        }
    }
}

// MARK: - Sheet Description

struct AppSheetDescription: View {
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

    func fontSize(_ value: CGFloat) -> Self {
        configure {
            $0.fontSize = value
        }
    }

    func textColor(_ value: Color) -> Self {
        configure {
            $0.textColor = value
        }
    }
}

// MARK: - Sheet Footer

struct AppSheetFooter<Content: View>: View {
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
        .frame(maxWidth: .infinity)
    }

    func spacing(_ value: CGFloat) -> Self {
        configure {
            $0.spacing = value
        }
    }
}

extension AppSheetFooter where Content == EmptyView {
    init() {
        self.content = EmptyView()
    }
}
