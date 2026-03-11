import SwiftUI

// MARK: - Command Environment

private struct CommandSearchTextKey: EnvironmentKey {
    static let defaultValue: String = ""
}

extension EnvironmentValues {
    var commandSearchText: String {
        get { self[CommandSearchTextKey.self] }
        set { self[CommandSearchTextKey.self] = newValue }
    }
}

// MARK: - Command

struct AppCommand<Content: View>: View {
    let content: Content
    var background: AnyShapeStyle = AnyShapeStyle(Color(UIColor.systemBackground))
    var cornerRadius: CGFloat = 6

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) { content }
            .background(background)
            .cornerRadius(cornerRadius)
    }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
}

// MARK: - Command Dialog

struct AppCommandDialog<Content: View>: View {
    @Binding var isPresented: Bool
    @Binding var searchText: String
    let content: Content
    var placeholder: String = "Search..."
    var emptyText: String = "No results found."
    var preferredMaxWidth: CGFloat = 640
    var contentInsets: CGFloat = 24
    var overlayColor: Color = .black.opacity(0.4)
    var cornerRadius: CGFloat = 6
    var shadowRadius: CGFloat = 20
    var shadowColor: Color = .black.opacity(0.2)

    @State private var hasResults: Bool = true

    init(
        isPresented: Binding<Bool>,
        searchText: Binding<String>,
        @ViewBuilder content: () -> Content
    ) {
        _isPresented = isPresented
        _searchText = searchText
        self.content = content()
    }

    private var maxWidth: CGFloat {
        min(preferredMaxWidth, UIScreen.main.bounds.width - contentInsets * 2)
    }

    var body: some View {
        ZStack {
            if isPresented {
                overlayColor
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { isPresented = false } }

                VStack(spacing: 0) {
                    AppCommandInput(searchText: $searchText, placeholder: placeholder)

                    AppCommandList {
                        content
                    }
                    .environment(\.commandSearchText, searchText)
                    .onPreferenceChange(CommandHasResultsKey.self) { hasResults = $0 }

                    if !hasResults && !searchText.isEmpty {
                        AppCommandEmpty(emptyText)
                    }
                }
                .frame(maxWidth: maxWidth)
                .background(Color(.systemBackground))
                .cornerRadius(cornerRadius)
                .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 10)
                .padding(contentInsets)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented)
        .onChange(of: isPresented) { newValue in
            if !newValue { searchText = "" }
        }
    }

    func placeholder(_ value: String) -> Self { configure { $0.placeholder = value } }
    func emptyText(_ value: String) -> Self { configure { $0.emptyText = value } }
    func preferredMaxWidth(_ value: CGFloat) -> Self { configure { $0.preferredMaxWidth = value } }
    func contentInsets(_ value: CGFloat) -> Self { configure { $0.contentInsets = value } }
    func overlayColor(_ value: Color) -> Self { configure { $0.overlayColor = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func shadowRadius(_ value: CGFloat) -> Self { configure { $0.shadowRadius = value } }
    func shadowColor(_ value: Color) -> Self { configure { $0.shadowColor = value } }
}

// MARK: - Command Has Results Preference

private struct CommandHasResultsKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

// MARK: - Command Input

struct AppCommandInput: View {
    @Binding var searchText: String
    var placeholder: String = "Search..."
    var fontSize: CGFloat = 14
    var height: CGFloat = 40
    var iconSize: CGFloat = 16
    var iconColor: Color = .primary.opacity(0.5)
    var horizontalInsets: CGFloat = 12
    var borderColor: Color = .gray.opacity(0.2)

    init(searchText: Binding<String>, placeholder: String = "Search...") {
        _searchText = searchText
        self.placeholder = placeholder
    }

    var body: some View {
        HStack(spacing: 8) {
            SafeIcon("Search", size: iconSize, color: iconColor)

            TextField(placeholder, text: $searchText)
                .font(.system(size: fontSize))
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, horizontalInsets)
        .frame(height: height)
        .overlay(
            Rectangle().frame(height: 1).foregroundColor(borderColor),
            alignment: .bottom
        )
    }

    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func height(_ value: CGFloat) -> Self { configure { $0.height = value } }
    func iconSize(_ value: CGFloat) -> Self { configure { $0.iconSize = value } }
    func iconColor(_ value: Color) -> Self { configure { $0.iconColor = value } }
    func horizontalInsets(_ value: CGFloat) -> Self { configure { $0.horizontalInsets = value } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }
}

// MARK: - Command List

struct AppCommandList<Content: View>: View {
    let content: Content
    var maxHeight: CGFloat = 300

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: maxHeight)
    }

    func maxHeight(_ value: CGFloat) -> Self { configure { $0.maxHeight = value } }
}

// MARK: - Command Empty

struct AppCommandEmpty: View {
    let text: String
    var fontSize: CGFloat = 14
    var textColor: Color = .secondary
    var verticalInsets: CGFloat = 24

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .foregroundColor(textColor)
            .padding(.vertical, verticalInsets)
            .frame(maxWidth: .infinity)
    }

    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func verticalInsets(_ value: CGFloat) -> Self { configure { $0.verticalInsets = value } }
}

// MARK: - Command Group

struct AppCommandGroup<Content: View>: View {
    @Environment(\.commandSearchText) private var searchText

    let title: String?
    let content: Content
    var titleFontSize: CGFloat = 12
    var titleFontWeight: Font.Weight = .medium
    var titleColor: Color = .secondary
    var horizontalInsets: CGFloat = 8
    var verticalInsets: CGFloat = 6
    var contentInsets: CGFloat = 4

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                Text(title)
                    .font(.system(size: titleFontSize, weight: titleFontWeight))
                    .foregroundColor(titleColor)
                    .padding(.horizontal, horizontalInsets)
                    .padding(.vertical, verticalInsets)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(contentInsets)
    }

    func titleFont(size: CGFloat, weight: Font.Weight = .medium) -> Self {
        configure { $0.titleFontSize = size; $0.titleFontWeight = weight }
    }

    func titleColor(_ value: Color) -> Self { configure { $0.titleColor = value } }
    func horizontalInsets(_ value: CGFloat) -> Self { configure { $0.horizontalInsets = value } }
    func verticalInsets(_ value: CGFloat) -> Self { configure { $0.verticalInsets = value } }
    func contentInsets(_ value: CGFloat) -> Self { configure { $0.contentInsets = value } }
}

// MARK: - Command Item

struct AppCommandItem: View {
    @Environment(\.commandSearchText) private var searchText

    let title: String
    let icon: String?
    let shortcut: String?
    let keywords: [String]
    let action: () -> Void
    var fontSize: CGFloat = 14
    var iconSize: CGFloat = 16
    var shortcutFontSize: CGFloat = 12
    var textColor: Color = .primary
    var accentColor: Color = Color(hsl: 0, 0, 0.961)
    var iconWidth: CGFloat = 20
    var horizontalInsets: CGFloat = 8
    var verticalInsets: CGFloat = 6
    var itemCornerRadius: CGFloat = 2

    init(
        _ title: String,
        icon: String? = nil,
        shortcut: String? = nil,
        keywords: [String] = [],
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.shortcut = shortcut
        self.keywords = keywords
        self.action = action
    }

    private var isVisible: Bool {
        if searchText.isEmpty { return true }
        let query = searchText.lowercased()
        if title.lowercased().contains(query) { return true }
        return keywords.contains { $0.lowercased().contains(query) }
    }

    var body: some View {
        if isVisible {
            Button(action: action) {
                HStack(spacing: 8) {
                    if let icon {
                        SafeIcon(icon, size: iconSize, color: textColor)
                            .frame(width: iconWidth, alignment: .center)
                    }
                    Text(title)
                        .font(.system(size: fontSize))
                        .foregroundColor(textColor)
                    Spacer(minLength: 8)
                    if let shortcut {
                        Text(shortcut)
                            .font(.system(size: shortcutFontSize))
                            .tracking(1)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, horizontalInsets)
                .padding(.vertical, verticalInsets)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(CommandItemButtonStyle(accentColor: accentColor, cornerRadius: itemCornerRadius))
            .preference(key: CommandHasResultsKey.self, value: true)
        }
    }

    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func iconSize(_ value: CGFloat) -> Self { configure { $0.iconSize = value } }
    func shortcutFontSize(_ value: CGFloat) -> Self { configure { $0.shortcutFontSize = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func accentColor(_ value: Color) -> Self { configure { $0.accentColor = value } }
    func iconWidth(_ value: CGFloat) -> Self { configure { $0.iconWidth = value } }
    func horizontalInsets(_ value: CGFloat) -> Self { configure { $0.horizontalInsets = value } }
    func verticalInsets(_ value: CGFloat) -> Self { configure { $0.verticalInsets = value } }
    func itemCornerRadius(_ value: CGFloat) -> Self { configure { $0.itemCornerRadius = value } }
}

// MARK: - Command Item Button Style

struct CommandItemButtonStyle: ButtonStyle {
    var accentColor: Color
    var cornerRadius: CGFloat = 2

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? accentColor : Color.clear)
            .cornerRadius(cornerRadius)
    }
}

// MARK: - Command Separator

struct AppCommandSeparator: View {
    var horizontalInsets: CGFloat = -4
    var verticalInsets: CGFloat = 4

    var body: some View {
        Divider()
            .padding(.horizontal, horizontalInsets)
            .padding(.vertical, verticalInsets)
    }

    func horizontalInsets(_ value: CGFloat) -> Self { configure { $0.horizontalInsets = value } }
    func verticalInsets(_ value: CGFloat) -> Self { configure { $0.verticalInsets = value } }
}

// MARK: - Command Shortcut

struct AppCommandShortcut: View {
    let text: String
    var fontSize: CGFloat = 12
    var tracking: CGFloat = 1
    var textColor: Color = .secondary

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .tracking(tracking)
            .foregroundColor(textColor)
    }

    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func tracking(_ value: CGFloat) -> Self { configure { $0.tracking = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
}
