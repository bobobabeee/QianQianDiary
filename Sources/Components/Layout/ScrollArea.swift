import SwiftUI

// MARK: - ScrollArea

struct AppScrollArea<Content: View>: View {
    let content: Content
    var axis: Axis.Set = .vertical
    var showsIndicators: Bool = true

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView(axis, showsIndicators: showsIndicators) {
            content
        }
    }

    // MARK: - Chain Methods

    func axis(_ value: Axis.Set) -> Self { configure { $0.axis = value } }
    func showsIndicators(_ value: Bool) -> Self { configure { $0.showsIndicators = value } }
}

// MARK: - Convenience

extension AppScrollArea {
    static func horizontal(@ViewBuilder content: () -> Content) -> AppScrollArea {
        var area = AppScrollArea(content: content)
        area.axis = .horizontal
        return area
    }

    static func vertical(@ViewBuilder content: () -> Content) -> AppScrollArea {
        var area = AppScrollArea(content: content)
        area.axis = .vertical
        return area
    }
}
