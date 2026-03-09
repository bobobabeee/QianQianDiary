import SwiftUI

// MARK: - Toggle Variant

enum ToggleVariant {
    case `default`
    case outline
}

// MARK: - Toggle Size

enum ToggleSize {
    case `default`
    case small
    case large
}

// MARK: - Toggle

struct AppToggle: View {
    @Binding var isOn: Bool
    let content: () -> AnyView
    var variant: ToggleVariant = .default
    var size: ToggleSize = .default
    var isEnabled: Bool = true
    var accentColor: Color = .init(hex: 0x3B82F6)
    var borderColor: Color = .init(hex: 0xE5E7EB)
    var cornerRadius: CGFloat = 6

    @FocusState private var isFocused: Bool

    init(isOn: Binding<Bool>, @ViewBuilder content: @escaping () -> some View) {
        _isOn = isOn
        self.content = { AnyView(content()) }
    }

    var body: some View {
        Button(action: {
            if isEnabled {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isOn.toggle()
                }
            }
        }) {
            HStack(spacing: 8) {
                content()
            }
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, horizontalPadding)
            .frame(height: height, alignment: .center)
            .frame(minWidth: height)
        }
        .buttonStyle(PlainButtonStyle())
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(currentBorderColor, lineWidth: borderWidth)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(focusRingColor, lineWidth: isFocused ? 1 : 0)
        )
        .shadow(color: shadowColor, radius: 2, x: 0, y: 1)
        .focused($isFocused)
        .disabled(!isEnabled)
    }

    private var height: CGFloat {
        switch size {
        case .small: 32
        case .large: 40
        case .default: 36
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .small: 6
        case .large: 10
        case .default: 8
        }
    }

    private var borderWidth: CGFloat { variant == .outline ? 1 : 0 }

    private var backgroundColor: Color {
        if isOn {
            let baseColor = accentColor.opacity(0.1)
            return isEnabled ? baseColor : baseColor.opacity(0.5)
        }
        return Color.clear
    }

    private var foregroundColor: Color {
        if isOn {
            return isEnabled ? accentColor : accentColor.opacity(0.5)
        }
        let baseColor = Color.primary.opacity(0.7)
        return isEnabled ? baseColor : baseColor.opacity(0.5)
    }

    private var currentBorderColor: Color {
        variant == .outline ? borderColor : Color.clear
    }

    private var focusRingColor: Color {
        isFocused ? accentColor : Color.clear
    }

    private var shadowColor: Color {
        variant == .outline ? Color.black.opacity(0.05) : Color.clear
    }

    // MARK: - Chain Methods

    func variant(_ value: ToggleVariant) -> Self { configure { $0.variant = value } }
    func size(_ value: ToggleSize) -> Self { configure { $0.size = value } }
    func disabled(_ value: Bool) -> Self { configure { $0.isEnabled = !value } }
    func accentColor(_ value: Color) -> Self { configure { $0.accentColor = value } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
}
