import SwiftUI

// MARK: - Textarea

struct AppTextarea: View {
    @Binding var text: String
    var placeholder: String = ""
    var minHeight: CGFloat = 60
    var fontSize: CGFloat = 16
    var isEnabled: Bool = true
    var borderColor: Color = .init(hex: 0xE5E7EB)
    var focusRingColor: Color = .init(hex: 0x3B82F6)
    var placeholderColor: Color = .gray.opacity(0.6)
    var cornerRadius: CGFloat = 6
    var textColor: Color = .primary

    @FocusState private var isFocused: Bool

    init(text: Binding<String>, placeholder: String = "") {
        _text = text
        self.placeholder = placeholder
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty, !isFocused {
                Text(placeholder)
                    .font(.system(size: fontSize))
                    .foregroundColor(isEnabled ? placeholderColor : placeholderColor.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $text)
                .font(.system(size: fontSize))
                .foregroundColor(isEnabled ? textColor : textColor.opacity(0.5))
                .padding(.horizontal, 4)
                .padding(.vertical, 0)
                .frame(minHeight: minHeight)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($isFocused)
        }
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

    private var currentBorderColor: Color {
        if !isEnabled { return borderColor.opacity(0.5) }
        return isFocused ? focusRingColor : borderColor
    }

    // MARK: - Chain Methods

    func minHeight(_ value: CGFloat) -> Self { configure { $0.minHeight = value } }
    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func disabled(_ value: Bool) -> Self { configure { $0.isEnabled = !value } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }
    func focusRingColor(_ value: Color) -> Self { configure { $0.focusRingColor = value } }
    func placeholderColor(_ value: Color) -> Self { configure { $0.placeholderColor = value } }
    func cornerRadius(_ value: CGFloat) -> Self { configure { $0.cornerRadius = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
}
