import SwiftUI

// MARK: - Label

struct AppLabel: View {
    let text: String
    var fontSize: CGFloat = 14
    var fontWeight: Font.Weight = .medium
    var textColor: Color = .primary
    var isEnabled: Bool = true

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundColor(isEnabled ? textColor : textColor.opacity(0.5))
            .lineSpacing(0)
    }

    // MARK: - Chain Methods

    func font(size: CGFloat, weight: Font.Weight = .medium) -> Self {
        configure { $0.fontSize = size; $0.fontWeight = weight }
    }

    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func disabled(_ value: Bool) -> Self { configure { $0.isEnabled = !value } }
}
