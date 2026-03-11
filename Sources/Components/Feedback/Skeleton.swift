import SwiftUI

// MARK: - Skeleton

struct AppSkeleton: View {
    @State private var isAnimating = false
    var width: CGFloat?
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 6
    var background: AnyShapeStyle = AnyShapeStyle(Color.primary.opacity(0.1))
    var animationDuration: Double = 1.0

    init() {}

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(background)
            .frame(width: width, height: height)
            .opacity(isAnimating ? 0.5 : 1.0)
            .animation(
                Animation.easeInOut(duration: animationDuration)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }

    // MARK: - Chain Methods

    func size(width: CGFloat?, height: CGFloat) -> Self {
        configure { $0.width = width; $0.height = height }
    }

    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func animationDuration(_ value: Double) -> Self { configure { $0.animationDuration = value } }
}

// MARK: - Convenience

extension AppSkeleton {
    static func text(width: CGFloat? = nil, lines: Int = 1) -> some View {
        VStack(spacing: 8) {
            ForEach(0 ..< lines, id: \.self) { _ in
                AppSkeleton()
                    .size(width: width, height: 16)
                    .cornerRadius(4)
            }
        }
    }

    static func circle(size: CGFloat = 40) -> AppSkeleton {
        AppSkeleton()
            .size(width: size, height: size)
            .cornerRadius(size / 2)
    }

    static func rectangle(width: CGFloat? = nil, height: CGFloat = 100) -> AppSkeleton {
        AppSkeleton()
            .size(width: width, height: height)
            .cornerRadius(8)
    }

    static func avatar(size: CGFloat = 40) -> AppSkeleton {
        AppSkeleton.circle(size: size)
    }
}
