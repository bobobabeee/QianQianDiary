import SwiftUI

// MARK: - Progress

struct AppProgress: View {
    let value: Double
    var maxValue: Double = 100
    var height: CGFloat = 8
    var primaryColor: Color = .accentColor
    var background: AnyShapeStyle?

    init(value: Double) {
        self.value = value
    }

    private var cornerRadius: CGFloat { height / 2 }

    private var computedBackground: AnyShapeStyle {
        background ?? AnyShapeStyle(primaryColor.opacity(0.2))
    }

    private var progress: CGFloat {
        CGFloat(min(max(value, 0), maxValue) / maxValue)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(computedBackground)
                    .frame(height: height)

                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(primaryColor)
                    .frame(width: geometry.size.width * progress, height: height)
            }
        }
        .frame(height: height)
    }

    // MARK: - Chain Methods

    func maxValue(_ value: Double) -> Self { configure { $0.maxValue = value } }
    func height(_ value: CGFloat) -> Self { configure { $0.height = value } }
    func primaryColor(_ value: Color) -> Self { configure { $0.primaryColor = value } }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
}

// MARK: - Convenience

extension AppProgress {
    static func percentage(_ value: Double) -> AppProgress {
        AppProgress(value: value)
    }
}
