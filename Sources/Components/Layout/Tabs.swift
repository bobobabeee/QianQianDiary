import SwiftUI

// MARK: - Tab Item

struct TabItem<Value: Hashable>: Identifiable {
    let id = UUID()
    let value: Value
    let label: String
    var icon: String?
    var isEnabled: Bool = true
}

// MARK: - Tabs

struct AppTabs<SelectionValue: Hashable, Content: View>: View {
    @Binding var selection: SelectionValue
    let content: Content
    var spacing: CGFloat = 8

    init(selection: Binding<SelectionValue>, @ViewBuilder content: () -> Content) {
        _selection = selection
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
    }

    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
}

// MARK: - Tabs List

struct AppTabsList<SelectionValue: Hashable>: View {
    @Binding var selection: SelectionValue
    let tabs: [TabItem<SelectionValue>]
    var fontSize: CGFloat = 14
    var fontWeight: Font.Weight = .medium
    var activeColor: Color = .primary
    var inactiveColor: Color = .secondary
    var activeBackgroundColor: Color = .init(UIColor.systemBackground)
    var listBackgroundColor: Color = .init(UIColor.secondarySystemBackground)
    var height: CGFloat = 36
    var iconSize: CGFloat = 16
    var itemCornerRadius: CGFloat = 6
    var listCornerRadius: CGFloat = 8
    var shadowColor: Color = .black.opacity(0.1)

    init(selection: Binding<SelectionValue>, tabs: [TabItem<SelectionValue>]) {
        _selection = selection
        self.tabs = tabs
    }

    init(selection: Binding<SelectionValue>, tabs: [(value: SelectionValue, label: String)]) {
        _selection = selection
        self.tabs = tabs.map { TabItem(value: $0.value, label: $0.label) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                Button(action: {
                    if tab.isEnabled {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selection = tab.value
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        if let icon = tab.icon {
                            SafeIcon(icon, size: iconSize)
                        }
                        Text(tab.label)
                    }
                    .font(.system(size: fontSize, weight: fontWeight))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .frame(height: height - 6)
                    .background(
                        selection == tab.value ?
                            activeBackgroundColor :
                            Color.clear
                    )
                    .foregroundColor(
                        selection == tab.value ?
                            activeColor :
                            (tab.isEnabled ? inactiveColor : inactiveColor.opacity(0.5))
                    )
                    .cornerRadius(itemCornerRadius)
                    .shadow(
                        color: selection == tab.value ? shadowColor : Color.clear,
                        radius: 2,
                        x: 0,
                        y: 1
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!tab.isEnabled)
                .opacity(tab.isEnabled ? 1.0 : 0.5)
            }
        }
        .padding(3)
        .background(listBackgroundColor)
        .cornerRadius(listCornerRadius)
    }

    // MARK: - Chain Methods

    func font(size: CGFloat, weight: Font.Weight = .medium) -> Self {
        configure { $0.fontSize = size; $0.fontWeight = weight }
    }

    func activeColor(_ value: Color) -> Self { configure { $0.activeColor = value } }
    func inactiveColor(_ value: Color) -> Self { configure { $0.inactiveColor = value } }
    func activeBackgroundColor(_ value: Color) -> Self { configure { $0.activeBackgroundColor = value } }
    func listBackgroundColor(_ value: Color) -> Self { configure { $0.listBackgroundColor = value } }
    func height(_ value: CGFloat) -> Self { configure { $0.height = value } }
    func shadowColor(_ value: Color) -> Self { configure { $0.shadowColor = value } }

    func cornerRadius(item: CGFloat, list: CGFloat) -> Self {
        configure { $0.itemCornerRadius = item; $0.listCornerRadius = list }
    }
}

// MARK: - Tabs Content

struct AppTabsContent<SelectionValue: Hashable, Content: View>: View {
    let value: SelectionValue
    @Binding var selection: SelectionValue
    let content: Content
    var padding: CGFloat = 0

    init(value: SelectionValue, selection: Binding<SelectionValue>, @ViewBuilder content: () -> Content) {
        self.value = value
        _selection = selection
        self.content = content()
    }

    var body: some View {
        if selection == value {
            content
                .padding(padding)
                .transition(.opacity)
        }
    }

    func padding(_ value: CGFloat) -> Self { configure { $0.padding = value } }
}
