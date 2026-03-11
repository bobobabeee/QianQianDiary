import SwiftUI

// MARK: - Switch

struct AppSwitch: View {
    @Binding var isOn: Bool
    var isEnabled: Bool = true
    var width: CGFloat = 36
    var height: CGFloat = 20
    var onColor: Color = .init(hex: 0x3B82F6)
    var offColor: Color = .init(hex: 0xE5E7EB)
    var thumbColor: Color = .white

    init(isOn: Binding<Bool>) {
        _isOn = isOn
    }

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            RoundedRectangle(cornerRadius: height / 2)
                .fill(backgroundColor)
                .frame(width: width, height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: height / 2)
                        .stroke(Color.clear, lineWidth: 2)
                )
                .shadow(color: shadowColor, radius: 2, x: 0, y: 1)

            Circle()
                .fill(thumbColor)
                .frame(width: thumbSize, height: thumbSize)
                .shadow(color: thumbShadowColor, radius: 2, x: 0, y: 1)
                .padding(thumbPadding)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isEnabled {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isOn.toggle()
                }
            }
        }
        .allowsHitTesting(isEnabled)
    }

    private var backgroundColor: Color {
        let baseColor = isOn ? onColor : offColor
        return isEnabled ? baseColor : baseColor.opacity(0.5)
    }

    private var shadowColor: Color {
        isEnabled ? Color.black.opacity(0.1) : Color.black.opacity(0.05)
    }

    private var thumbShadowColor: Color {
        isEnabled ? Color.black.opacity(0.2) : Color.black.opacity(0.1)
    }

    private var thumbSize: CGFloat { height - 4 }
    private var thumbPadding: CGFloat { 2 }

    // MARK: - Chain Methods

    func disabled(_ value: Bool) -> Self { configure { $0.isEnabled = !value } }
    func size(width: CGFloat, height: CGFloat) -> Self { configure { $0.width = width; $0.height = height } }
    func onColor(_ value: Color) -> Self { configure { $0.onColor = value } }
    func offColor(_ value: Color) -> Self { configure { $0.offColor = value } }
    func thumbColor(_ value: Color) -> Self { configure { $0.thumbColor = value } }
}
