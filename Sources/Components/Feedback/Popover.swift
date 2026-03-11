import Popovers
import SwiftUI

// MARK: - Popover Content Style

struct AppPopoverContent<Content: View>: View {
    let content: Content
    var width: CGFloat = 288
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 6
    var background: AnyShapeStyle = AnyShapeStyle(Color(UIColor.systemBackground))
    var borderColor: Color = .gray.opacity(0.2)
    var shadowColor: Color = .black.opacity(0.15)
    var shadowRadius: CGFloat = 10

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading) {
            content
        }
        .padding(padding)
        .frame(width: width)
        .background(background)
        .cornerRadius(cornerRadius)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    // MARK: - Chain Methods

    func width(_ value: CGFloat) -> Self { configure { $0.width = value } }
    func padding(_ value: CGFloat) -> Self { configure { $0.padding = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }

    func shadow(color: Color = .black.opacity(0.1), radius: CGFloat) -> Self {
        configure { $0.shadowColor = color; $0.shadowRadius = radius }
    }
}

// MARK: - Popover Side

enum PopoverSide {
    case auto
    case top
    case bottom
    case left
    case right
}

// MARK: - Popover Modifier

struct AppPopoverModifier<PopoverContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let side: PopoverSide
    let sideOffset: CGFloat
    let popoverContent: () -> PopoverContent

    @State private var sourceFrame: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear.onAppear {
                        sourceFrame = geometry.frame(in: .global)
                    }
                    .onChange(of: geometry.frame(in: .global)) { newFrame in
                        sourceFrame = newFrame
                    }
                }
            )
            .popover(
                present: $isPresented,
                attributes: { attributes in
                    let anchors = calculateAnchors(for: sourceFrame)
                    attributes.position = .absolute(
                        originAnchor: anchors.origin,
                        popoverAnchor: anchors.popover
                    )

                    attributes.sourceFrameInset = UIEdgeInsets(
                        top: -sideOffset,
                        left: -sideOffset,
                        bottom: -sideOffset,
                        right: -sideOffset
                    )

                    attributes.dismissal.mode = .tapOutside
                    attributes.dismissal.excludedFrames = { [sourceFrame] }
                    attributes.rubberBandingMode = .none
                }
            ) {
                popoverContent()
            }
    }

    private func calculateAnchors(for frame: CGRect)
        -> (origin: Popover.Attributes.Position.Anchor, popover: Popover.Attributes.Position.Anchor)
    {
        switch side {
        case .top:
            return (.top, .bottom)
        case .bottom:
            return (.bottom, .top)
        case .left:
            return (.left, .right)
        case .right:
            return (.right, .left)
        case .auto:
            let screenHeight = UIScreen.main.bounds.height
            let screenWidth = UIScreen.main.bounds.width

            let spaceAbove = frame.minY
            let spaceBelow = screenHeight - frame.maxY
            let spaceLeft = frame.minX
            let spaceRight = screenWidth - frame.maxX

            if spaceBelow >= 200 {
                return (.bottom, .top)
            } else if spaceAbove >= 200 {
                return (.top, .bottom)
            } else if spaceRight >= 200 {
                return (.right, .left)
            } else if spaceLeft >= 200 {
                return (.left, .right)
            } else {
                return spaceBelow >= spaceAbove ? (.bottom, .top) : (.top, .bottom)
            }
        }
    }
}

// MARK: - View Extension

extension View {
    func appPopover(
        isPresented: Binding<Bool>,
        side: PopoverSide = .auto,
        sideOffset: CGFloat = 4,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        modifier(AppPopoverModifier(
            isPresented: isPresented,
            side: side,
            sideOffset: sideOffset,
            popoverContent: content
        ))
    }
}
