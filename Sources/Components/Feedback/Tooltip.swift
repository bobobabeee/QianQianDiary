import Popovers
import SwiftUI

// MARK: - Tooltip View Style

struct AppTooltipView: View {
    let text: String
    var fontSize: CGFloat = 12
    var horizontalPadding: CGFloat = 12
    var verticalPadding: CGFloat = 6
    var cornerRadius: CGFloat = 6
    var background: AnyShapeStyle = AnyShapeStyle(Color.primary)
    var textColor: Color = .white

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .foregroundColor(textColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(background)
            .cornerRadius(cornerRadius)
    }

    // MARK: - Chain Methods

    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }

    func padding(horizontal: CGFloat, vertical: CGFloat) -> Self {
        configure { $0.horizontalPadding = horizontal; $0.verticalPadding = vertical }
    }
}

// MARK: - Tooltip Side

enum TooltipSide {
    case auto
    case top
    case bottom
    case left
    case right
}

// MARK: - Tooltip Modifier

struct AppTooltipModifier: ViewModifier {
    @Binding var isPresented: Bool
    let text: String
    let side: TooltipSide
    let sideOffset: CGFloat
    var background: AnyShapeStyle = AnyShapeStyle(Color.primary)
    var textColor: Color = .white

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
                }
            ) {
                AppTooltipView(text)
                    .background(background)
                    .textColor(textColor)
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

            if spaceBelow >= 100 {
                return (.bottom, .top)
            } else if spaceAbove >= 100 {
                return (.top, .bottom)
            } else if spaceRight >= 150 {
                return (.right, .left)
            } else if spaceLeft >= 150 {
                return (.left, .right)
            } else {
                return spaceBelow >= spaceAbove ? (.bottom, .top) : (.top, .bottom)
            }
        }
    }
}

// MARK: - View Extension

extension View {
    func appTooltip(
        isPresented: Binding<Bool>,
        text: String,
        side: TooltipSide = .auto,
        sideOffset: CGFloat = 4,
        backgroundColor: Color = .primary,
        textColor: Color = .white
    ) -> some View {
        modifier(AppTooltipModifier(
            isPresented: isPresented,
            text: text,
            side: side,
            sideOffset: sideOffset,
            background: AnyShapeStyle(backgroundColor),
            textColor: textColor
        ))
    }
}
