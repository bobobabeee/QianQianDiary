import SwiftUI

// MARK: - Carousel Orientation

enum CarouselOrientation {
    case horizontal
    case vertical
}

// MARK: - Carousel Scroll Handler

class CarouselScrollHandler: ObservableObject {
    var scrollNext: (() -> Void)?
    var scrollPrev: (() -> Void)?
}

// MARK: - Carousel

struct AppCarousel<Content: View>: View {
    let content: Content
    @Binding var currentIndex: Int
    var itemCount: Int
    var orientation: CarouselOrientation = .horizontal
    var showButtons: Bool = true
    var buttonOffset: CGFloat = 48
    var spacing: CGFloat = 16
    var loop: Bool = false

    @StateObject private var scrollHandler = CarouselScrollHandler()

    init(
        currentIndex: Binding<Int>,
        itemCount: Int,
        @ViewBuilder content: () -> Content
    ) {
        _currentIndex = currentIndex
        self.itemCount = itemCount
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                content
                    .environment(\.carouselOrientation, orientation)
                    .environment(\.carouselSpacing, spacing)
                    .environment(\.carouselLoop, loop)
                    .environment(\.carouselItemCount, itemCount)
                    .environmentObject(scrollHandler)

                if showButtons {
                    navigationButtons(geometry: geometry)
                }
            }
        }
    }

    @ViewBuilder
    private func navigationButtons(geometry: GeometryProxy) -> some View {
        if orientation == .horizontal {
            HStack {
                AppCarouselPrevious(
                    canScroll: loop || currentIndex > 0,
                    action: { scrollHandler.scrollPrev?() }
                )
                .offset(x: -buttonOffset + 32)

                Spacer()

                AppCarouselNext(
                    canScroll: loop || currentIndex < itemCount - 1,
                    action: { scrollHandler.scrollNext?() }
                )
                .offset(x: buttonOffset - 32)
            }
            .frame(height: geometry.size.height)
        } else {
            VStack {
                AppCarouselPrevious(
                    canScroll: loop || currentIndex > 0,
                    action: { scrollHandler.scrollPrev?() },
                    isVertical: true
                )
                .offset(y: -buttonOffset + 32)

                Spacer()

                AppCarouselNext(
                    canScroll: loop || currentIndex < itemCount - 1,
                    action: { scrollHandler.scrollNext?() },
                    isVertical: true
                )
                .offset(y: buttonOffset - 32)
            }
            .frame(width: geometry.size.width)
        }
    }

    func orientation(_ value: CarouselOrientation) -> Self { configure { $0.orientation = value } }
    func showButtons(_ value: Bool) -> Self { configure { $0.showButtons = value } }
    func buttonOffset(_ value: CGFloat) -> Self { configure { $0.buttonOffset = value } }
    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
    func loop(_ value: Bool) -> Self { configure { $0.loop = value } }
}

// MARK: - Carousel Content

struct AppCarouselContent<ItemContent: View>: View {
    @Binding var currentIndex: Int
    let itemCount: Int
    let itemContent: (Int) -> ItemContent

    @Environment(\.carouselSpacing) private var spacing
    @EnvironmentObject private var scrollHandler: CarouselScrollHandler

    @State private var internalIndex: Int = 1
    @State private var dragOffset: CGFloat = 0
    @State private var isAnimating: Bool = true

    init(
        currentIndex: Binding<Int>,
        itemCount: Int,
        @ViewBuilder itemContent: @escaping (Int) -> ItemContent
    ) {
        _currentIndex = currentIndex
        self.itemCount = itemCount
        self.itemContent = itemContent
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            HStack(spacing: spacing) {
                itemContent(itemCount - 1)
                    .frame(width: width)

                ForEach(0 ..< itemCount, id: \.self) { index in
                    itemContent(index)
                        .frame(width: width)
                }

                itemContent(0)
                    .frame(width: width)
            }
            .offset(x: -CGFloat(internalIndex) * (width + spacing) + dragOffset)
            .animation(isAnimating ? .easeInOut(duration: 0.3) : .none, value: internalIndex)
            .animation(.interactiveSpring(), value: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        if value.translation.width < -threshold {
                            scrollNext()
                        } else if value.translation.width > threshold {
                            scrollPrev()
                        }
                        withAnimation(.interactiveSpring()) {
                            dragOffset = 0
                        }
                    }
            )
            .onAppear {
                internalIndex = currentIndex + 1
                scrollHandler.scrollNext = scrollNext
                scrollHandler.scrollPrev = scrollPrev
            }
        }
        .clipped()
    }

    private func scrollNext() {
        isAnimating = true
        internalIndex += 1
        currentIndex = (currentIndex + 1) % itemCount

        if internalIndex > itemCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isAnimating = false
                internalIndex = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isAnimating = true
                }
            }
        }
    }

    private func scrollPrev() {
        isAnimating = true
        internalIndex -= 1
        currentIndex = (currentIndex - 1 + itemCount) % itemCount

        if internalIndex < 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isAnimating = false
                internalIndex = itemCount
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isAnimating = true
                }
            }
        }
    }
}

// MARK: - Carousel Item

struct AppCarouselItem<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
    }
}

// MARK: - Carousel Previous Button

struct AppCarouselPrevious: View {
    var canScroll: Bool
    var action: () -> Void
    var isVertical: Bool = false
    var size: CGFloat = 32
    var iconSize: CGFloat = 16
    var background: AnyShapeStyle = AnyShapeStyle(Color(UIColor.systemBackground))
    var borderColor: Color = .gray.opacity(0.3)

    init(canScroll: Bool, action: @escaping () -> Void, isVertical: Bool = false) {
        self.canScroll = canScroll
        self.action = action
        self.isVertical = isVertical
    }

    var body: some View {
        Button(action: action) {
            SafeIcon(isVertical ? "ChevronUp" : "ChevronLeft", size: iconSize, color: canScroll ? .primary : .primary.opacity(0.3))
                .frame(width: size, height: size)
                .background(background)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: 1)
                )
        }
        .disabled(!canScroll)
    }

    func size(_ value: CGFloat) -> Self { configure { $0.size = value } }
    func iconSize(_ value: CGFloat) -> Self { configure { $0.iconSize = value } }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }
}

// MARK: - Carousel Next Button

struct AppCarouselNext: View {
    var canScroll: Bool
    var action: () -> Void
    var isVertical: Bool = false
    var size: CGFloat = 32
    var iconSize: CGFloat = 16
    var background: AnyShapeStyle = AnyShapeStyle(Color(UIColor.systemBackground))
    var borderColor: Color = .gray.opacity(0.3)

    init(canScroll: Bool, action: @escaping () -> Void, isVertical: Bool = false) {
        self.canScroll = canScroll
        self.action = action
        self.isVertical = isVertical
    }

    var body: some View {
        Button(action: action) {
            SafeIcon(isVertical ? "ChevronDown" : "ChevronRight", size: iconSize, color: canScroll ? .primary : .primary.opacity(0.3))
                .frame(width: size, height: size)
                .background(background)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: 1)
                )
        }
        .disabled(!canScroll)
    }

    func size(_ value: CGFloat) -> Self { configure { $0.size = value } }
    func iconSize(_ value: CGFloat) -> Self { configure { $0.iconSize = value } }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }
}

// MARK: - Carousel Indicator

struct AppCarouselIndicator: View {
    @Binding var currentIndex: Int
    var itemCount: Int
    var activeColor: Color = .primary
    var inactiveColor: Color = .gray.opacity(0.3)
    var dotSize: CGFloat = 8
    var spacing: CGFloat = 8

    init(currentIndex: Binding<Int>, itemCount: Int) {
        _currentIndex = currentIndex
        self.itemCount = itemCount
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0 ..< itemCount, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? activeColor : inactiveColor)
                    .frame(width: dotSize, height: dotSize)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentIndex = index
                        }
                    }
            }
        }
    }

    func activeColor(_ value: Color) -> Self { configure { $0.activeColor = value } }
    func inactiveColor(_ value: Color) -> Self { configure { $0.inactiveColor = value } }
    func dotSize(_ value: CGFloat) -> Self { configure { $0.dotSize = value } }
    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
}

// MARK: - Environment Keys

private struct CarouselOrientationKey: EnvironmentKey {
    static let defaultValue: CarouselOrientation = .horizontal
}

private struct CarouselSpacingKey: EnvironmentKey {
    static let defaultValue: CGFloat = 16
}

private struct CarouselLoopKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct CarouselItemCountKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

extension EnvironmentValues {
    var carouselOrientation: CarouselOrientation {
        get { self[CarouselOrientationKey.self] }
        set { self[CarouselOrientationKey.self] = newValue }
    }

    var carouselSpacing: CGFloat {
        get { self[CarouselSpacingKey.self] }
        set { self[CarouselSpacingKey.self] = newValue }
    }

    var carouselLoop: Bool {
        get { self[CarouselLoopKey.self] }
        set { self[CarouselLoopKey.self] = newValue }
    }

    var carouselItemCount: Int {
        get { self[CarouselItemCountKey.self] }
        set { self[CarouselItemCountKey.self] = newValue }
    }
}
