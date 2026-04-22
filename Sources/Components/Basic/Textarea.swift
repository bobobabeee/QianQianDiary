import SwiftUI
import UIKit

// MARK: - UITextView wrapper for full keyboard support (including Chinese pinyin)

private struct ChineseFriendlyTextView: UIViewRepresentable {
    @Binding var text: String
    var fontSize: CGFloat
    var textColor: Color
    var isEnabled: Bool
    var minHeight: CGFloat
    var onFocusChange: (Bool) -> Void

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.font = .systemFont(ofSize: fontSize)
        tv.textColor = UIColor(textColor)
        tv.backgroundColor = .clear
        tv.isScrollEnabled = true
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        tv.keyboardType = .default
        tv.returnKeyType = .default
        tv.autocorrectionType = .default
        tv.spellCheckingType = .default
        tv.textContentType = nil
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.parent = self
        if uiView.text != text {
            // 程序化改 text 会同步触发 textViewDidChange，若在此时写 Binding 会触发「在视图更新中改状态」
            context.coordinator.isApplyingExternalText = true
            uiView.text = text
            context.coordinator.isApplyingExternalText = false
        }
        uiView.font = .systemFont(ofSize: fontSize)
        uiView.textColor = UIColor(textColor)
        uiView.isUserInteractionEnabled = isEnabled
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: ChineseFriendlyTextView
        /// true 时表示来自 SwiftUI updateUIView 赋值，忽略 delegate 避免在视图更新周期写 Binding
        var isApplyingExternalText = false
        init(_ parent: ChineseFriendlyTextView) { self.parent = parent }
        func textViewDidChange(_ textView: UITextView) {
            if isApplyingExternalText { return }
            let newText = textView.text ?? ""
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if self.parent.text != newText {
                    self.parent.text = newText
                }
            }
        }
        func textViewDidBeginEditing(_ textView: UITextView) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.onFocusChange(true)
            }
        }
        func textViewDidEndEditing(_ textView: UITextView) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.onFocusChange(false)
            }
        }
    }
}

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

    @State private var isFocused: Bool = false

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

            ChineseFriendlyTextView(
                text: $text,
                fontSize: fontSize,
                textColor: isEnabled ? textColor : textColor.opacity(0.5),
                isEnabled: isEnabled,
                minHeight: minHeight,
                onFocusChange: { focused in
                    Task { @MainActor in
                        isFocused = focused
                    }
                }
            )
            .frame(minHeight: minHeight)
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
