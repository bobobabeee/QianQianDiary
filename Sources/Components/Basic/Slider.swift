import SwiftUI

// MARK: - Slider

struct AppSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 0 ... 100
    var step: Double = 1
    var isEnabled: Bool = true
    var trackHeight: CGFloat = 6
    var thumbSize: CGFloat = 16
    var primaryColor: Color = .init(hex: 0x3B82F6)
    var thumbBackground: AnyShapeStyle = AnyShapeStyle(Color(UIColor.systemBackground))

    @GestureState private var isDragging = false

    init(value: Binding<Double>, range: ClosedRange<Double> = 0 ... 100) {
        _value = value
        self.range = range
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(trackColor)
                    .frame(height: trackHeight)

                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(rangeColor)
                    .frame(width: thumbPosition(in: geometry.size.width), height: trackHeight)

                Circle()
                    .fill(thumbBackground)
                    .overlay(
                        Circle()
                            .strokeBorder(borderColor, lineWidth: 1)
                    )
                    .shadow(color: shadowColor, radius: 2, x: 0, y: 1)
                    .frame(width: thumbSize, height: thumbSize)
                    .offset(x: thumbPosition(in: geometry.size.width) - thumbSize / 2)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .updating($isDragging) { _, state, _ in
                                state = true
                            }
                            .onChanged { gesture in
                                if isEnabled {
                                    updateValue(with: gesture.location.x, in: geometry.size.width)
                                }
                            }
                    )
            }
            .frame(height: thumbSize)
        }
        .frame(height: thumbSize)
        .allowsHitTesting(isEnabled)
    }

    private var trackColor: Color {
        isEnabled ? primaryColor.opacity(0.2) : primaryColor.opacity(0.1)
    }

    private var rangeColor: Color {
        isEnabled ? primaryColor : primaryColor.opacity(0.5)
    }

    private var borderColor: Color {
        isEnabled ? primaryColor.opacity(0.5) : primaryColor.opacity(0.25)
    }


    private var shadowColor: Color {
        isEnabled ? Color.black.opacity(0.1) : Color.black.opacity(0.05)
    }

    private func thumbPosition(in width: CGFloat) -> CGFloat {
        let normalizedValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return max(thumbSize / 2, min(width - thumbSize / 2, CGFloat(normalizedValue) * width))
    }

    private func updateValue(with position: CGFloat, in width: CGFloat) {
        let normalizedPosition = max(0, min(1, position / width))
        var newValue = range.lowerBound + normalizedPosition * (range.upperBound - range.lowerBound)
        if step > 0 {
            newValue = round(newValue / step) * step
        }
        value = min(range.upperBound, max(range.lowerBound, newValue))
    }

    // MARK: - Chain Methods

    func step(_ value: Double) -> Self { configure { $0.step = value } }
    func disabled(_ value: Bool) -> Self { configure { $0.isEnabled = !value } }
    func trackHeight(_ value: CGFloat) -> Self { configure { $0.trackHeight = value } }
    func thumbSize(_ value: CGFloat) -> Self { configure { $0.thumbSize = value } }
    func primaryColor(_ value: Color) -> Self { configure { $0.primaryColor = value } }
    func thumbBackground<S: ShapeStyle>(_ style: S) -> Self { configure { $0.thumbBackground = AnyShapeStyle(style) } }
}
