import SwiftUI

// MARK: - Separator Orientation

enum SeparatorOrientation {
    case horizontal
    case vertical
}

// MARK: - Separator

struct AppSeparator: View {
    var orientation: SeparatorOrientation = .horizontal
    var color: Color = .init(hex: 0xE5E7EB)
    var thickness: CGFloat = 1

    init(orientation: SeparatorOrientation = .horizontal) {
        self.orientation = orientation
    }

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(
                width: orientation == .vertical ? thickness : nil,
                height: orientation == .horizontal ? thickness : nil
            )
    }

    // MARK: - Chain Methods

    func color(_ value: Color) -> Self { configure { $0.color = value } }
    func thickness(_ value: CGFloat) -> Self { configure { $0.thickness = value } }
}

// MARK: - Convenience

extension AppSeparator {
    static var horizontal: AppSeparator {
        AppSeparator(orientation: .horizontal)
    }

    static var vertical: AppSeparator {
        AppSeparator(orientation: .vertical)
    }
}
