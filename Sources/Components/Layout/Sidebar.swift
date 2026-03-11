import SwiftUI

// MARK: - Sidebar Variant

enum SidebarVariant {
    case sidebar
    case floating
    case inset
}

// MARK: - Sidebar Menu Item Size

enum SidebarMenuItemSize {
    case small
    case `default`
    case large
}

// MARK: - Sidebar

struct AppSidebar<Content: View>: View {
    @Binding var isOpen: Bool
    let content: Content
    var side: SheetSide = .left
    var variant: SidebarVariant = .sidebar
    var width: CGFloat = 256
    var background: AnyShapeStyle = AnyShapeStyle(Color(UIColor.systemBackground))
    var overlayColor: Color = .black.opacity(0.3)
    var shadowColor: Color = .black.opacity(0.1)
    var shadowRadius: CGFloat = 8

    init(isOpen: Binding<Bool>, @ViewBuilder content: () -> Content) {
        _isOpen = isOpen
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: sideAlignment) {
            if isOpen {
                overlayColor
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { isOpen = false }
                    }
                    .zIndex(0)

                sidebarContent
                    .transition(transitionForSide)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isOpen)
    }

    @ViewBuilder
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .background(background)
        .shadow(color: shadowColor, radius: shadowRadius, x: side == .left ? 4 : -4, y: 0)
    }

    private var sideAlignment: Alignment {
        side == .left ? .leading : .trailing
    }

    private var transitionForSide: AnyTransition {
        side == .left ? .move(edge: .leading) : .move(edge: .trailing)
    }

    // MARK: - Chain Methods

    func side(_ value: SheetSide) -> Self { configure { $0.side = value } }
    func variant(_ value: SidebarVariant) -> Self { configure { $0.variant = value } }
    func width(_ value: CGFloat) -> Self { configure { $0.width = value } }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func overlayColor(_ value: Color) -> Self { configure { $0.overlayColor = value } }

    func shadow(color: Color = .black.opacity(0.1), radius: CGFloat) -> Self {
        configure { $0.shadowColor = color; $0.shadowRadius = radius }
    }
}

// MARK: - Sidebar Header

struct AppSidebarHeader<Content: View>: View {
    let content: Content
    var spacing: CGFloat = 8
    var padding: CGFloat = 8

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .padding(padding)
    }

    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
    func padding(_ value: CGFloat) -> Self { configure { $0.padding = value } }
}

extension AppSidebarHeader where Content == EmptyView {
    init() {
        self.content = EmptyView()
    }
}

// MARK: - Sidebar Content

struct AppSidebarContent<Content: View>: View {
    let content: Content
    var spacing: CGFloat = 8
    var padding: CGFloat = 8

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
        }
    }

    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
    func padding(_ value: CGFloat) -> Self { configure { $0.padding = value } }
}

// MARK: - Sidebar Footer

struct AppSidebarFooter<Content: View>: View {
    let content: Content
    var spacing: CGFloat = 8
    var padding: CGFloat = 8

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
        .padding(padding)
    }

    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
    func padding(_ value: CGFloat) -> Self { configure { $0.padding = value } }
}

extension AppSidebarFooter where Content == EmptyView {
    init() {
        self.content = EmptyView()
    }
}

// MARK: - Sidebar Group

struct AppSidebarGroup<Content: View>: View {
    let content: Content
    var padding: CGFloat = 8

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(padding)
    }

    func padding(_ value: CGFloat) -> Self { configure { $0.padding = value } }
}

// MARK: - Sidebar Group Label

struct AppSidebarGroupLabel: View {
    let text: String
    var fontSize: CGFloat = 12
    var fontWeight: Font.Weight = .medium
    var textColor: Color = .secondary
    var height: CGFloat = 32

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundColor(textColor)
            .frame(height: height)
            .padding(.horizontal, 8)
    }

    func font(size: CGFloat, weight: Font.Weight = .medium) -> Self {
        configure { $0.fontSize = size; $0.fontWeight = weight }
    }

    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func height(_ value: CGFloat) -> Self { configure { $0.height = value } }
}

// MARK: - Sidebar Menu

struct AppSidebarMenu<Content: View>: View {
    let content: Content
    var spacing: CGFloat = 4

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: spacing) {
            content
        }
        .frame(maxWidth: .infinity)
    }

    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
}

// MARK: - Sidebar Menu Item

struct AppSidebarMenuItem<Content: View>: View {
    let action: () -> Void
    let content: Content
    var isActive: Bool = false
    var size: SidebarMenuItemSize = .default
    var fontSize: CGFloat = 14
    var activeColor: Color = .primary
    var inactiveColor: Color = .secondary
    var activeBackgroundColor: Color = .gray.opacity(0.15)
    var cornerRadius: CGFloat = 6

    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                content
                    .font(.system(size: fontSize, weight: isActive ? .medium : .regular))
                    .foregroundColor(isActive ? activeColor : inactiveColor)
                Spacer()
            }
            .padding(.horizontal, 8)
            .frame(height: itemHeight)
            .frame(maxWidth: .infinity)
            .background(isActive ? activeBackgroundColor : Color.clear)
            .cornerRadius(cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var itemHeight: CGFloat {
        switch size {
        case .small: 28
        case .default: 32
        case .large: 48
        }
    }

    // MARK: - Chain Methods

    func active(_ value: Bool) -> Self { configure { $0.isActive = value } }
    func size(_ value: SidebarMenuItemSize) -> Self { configure { $0.size = value } }
    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func activeColor(_ value: Color) -> Self { configure { $0.activeColor = value } }
    func inactiveColor(_ value: Color) -> Self { configure { $0.inactiveColor = value } }
    func activeBackgroundColor(_ value: Color) -> Self { configure { $0.activeBackgroundColor = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
}
