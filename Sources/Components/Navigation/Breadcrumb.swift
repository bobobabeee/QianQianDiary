import SwiftUI

// MARK: - Breadcrumb

struct AppBreadcrumb: View {
    let items: [(label: String, action: (() -> Void)?)]
    var separator: String = "/"
    var fontSize: CGFloat = 14
    var spacing: CGFloat = 6
    var activeColor: Color = .primary
    var inactiveColor: Color = .secondary

    init(items: [(label: String, action: (() -> Void)?)]) {
        self.items = items
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(items.indices, id: \.self) { index in
                if let action = items[index].action {
                    Button(action: action) {
                        Text(items[index].label)
                            .font(.system(size: fontSize))
                            .foregroundColor(inactiveColor)
                    }
                } else {
                    Text(items[index].label)
                        .font(.system(size: fontSize))
                        .foregroundColor(activeColor)
                }

                if index < items.count - 1 {
                    Text(separator)
                        .font(.system(size: fontSize))
                        .foregroundColor(inactiveColor)
                }
            }
        }
    }

    func separator(_ value: String) -> Self { configure { $0.separator = value } }
    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
    func activeColor(_ value: Color) -> Self { configure { $0.activeColor = value } }
    func inactiveColor(_ value: Color) -> Self { configure { $0.inactiveColor = value } }
}
