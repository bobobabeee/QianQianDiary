import Popovers
import SwiftUI

// MARK: - HoverCard Side

enum HoverCardSide {
    case auto
    case top
    case bottom
    case left
    case right
}

// MARK: - HoverCard

struct AppHoverCard<Trigger: View, Content: View>: View {
    @State private var isPresented: Bool = false
    @State private var sourceFrame: CGRect = .zero
    let trigger: Trigger
    let content: Content
    var width: CGFloat = 256
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 6
    var shadowRadius: CGFloat = 10
    var shadowColor: Color = .black.opacity(0.15)
    var borderColor: Color = .gray.opacity(0.2)
    var sideOffset: CGFloat = 4
    var side: HoverCardSide = .auto

    init(@ViewBuilder trigger: () -> Trigger, @ViewBuilder content: () -> Content) {
        self.trigger = trigger()
        self.content = content()
    }

    var body: some View {
        trigger
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
            .contentShape(Rectangle())
            .onTapGesture {
                isPresented.toggle()
            }
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
                }
            ) {
                VStack(alignment: .leading) { content }
                    .padding(padding)
                    .frame(width: width)
                    .background(Color(.systemBackground))
                    .cornerRadius(cornerRadius)
                    .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: 1)
                    )
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

    // MARK: - Chain Methods

    func width(_ value: CGFloat) -> Self { configure { $0.width = value } }
    func padding(_ value: CGFloat) -> Self { configure { $0.padding = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }
    func sideOffset(_ value: CGFloat) -> Self { configure { $0.sideOffset = value } }
    func side(_ value: HoverCardSide) -> Self { configure { $0.side = value } }

    func shadow(color: Color = .black.opacity(0.15), radius: CGFloat) -> Self {
        configure { $0.shadowColor = color; $0.shadowRadius = radius }
    }
}
