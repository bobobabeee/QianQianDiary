import SwiftUI

// MARK: - Input

struct AppInput: View {
    @Binding var text: String
    var placeholder: String = ""
    var isEnabled: Bool = true
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var height: CGFloat = 36
    var fontSize: CGFloat = 16
    var cornerRadius: CGFloat = 6
    var borderColor: Color = .init(hex: 0xE5E7EB)
    var focusRingColor: Color = .init(hex: 0x3B82F6)
    var textColor: Color = .primary

    @FocusState private var isFocused: Bool

    init(text: Binding<String>, placeholder: String = "") {
        _text = text
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .focused($isFocused)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(height: height)
        .font(.system(size: fontSize))
        .foregroundColor(isEnabled ? textColor : textColor.opacity(0.5))
        .background(Color.clear)
        .cornerRadius(cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(currentBorderColor, lineWidth: isFocused ? 2 : 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .disabled(!isEnabled)
    }

    private var horizontalPadding: CGFloat { height * 0.33 }
    private var verticalPadding: CGFloat { height * 0.11 }

    private var currentBorderColor: Color {
        if !isEnabled { return borderColor.opacity(0.5) }
        return isFocused ? focusRingColor : borderColor
    }

    // MARK: - Chain Methods

    func secure(_ value: Bool = true) -> Self { configure { $0.isSecure = value } }
    func disabled(_ value: Bool) -> Self { configure { $0.isEnabled = !value } }
    func keyboardType(_ value: UIKeyboardType) -> Self { configure { $0.keyboardType = value } }
    func height(_ value: CGFloat) -> Self { configure { $0.height = value } }
    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }
    func focusRingColor(_ value: Color) -> Self { configure { $0.focusRingColor = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
}
