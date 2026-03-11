import SwiftUI

// MARK: - Checkbox

struct AppCheckbox: View {
    @Binding var isChecked: Bool
    var isEnabled: Bool = true
    var size: CGFloat = 16
    var primaryColor: Color = .init(hex: 0x3B82F6)
    var checkColor: Color = .white

    init(isChecked: Binding<Bool>) {
        _isChecked = isChecked
    }

    var body: some View {
        Button(action: {
            if isEnabled {
                isChecked.toggle()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: size / 8)
                    .fill(isChecked ? checkboxColor : Color.clear)
                    .frame(width: size, height: size)

                RoundedRectangle(cornerRadius: size / 8)
                    .stroke(checkboxColor, lineWidth: 1)
                    .frame(width: size, height: size)

                if isChecked {
                    SafeIcon("Check", size: size * 0.75, color: checkColor)
                }
            }
        }
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .disabled(!isEnabled)
    }

    private var checkboxColor: Color {
        isEnabled ? primaryColor : primaryColor.opacity(0.5)
    }

    // MARK: - Chain Methods

    func disabled(_ value: Bool) -> Self { configure { $0.isEnabled = !value } }
    func size(_ value: CGFloat) -> Self { configure { $0.size = value } }
    func primaryColor(_ value: Color) -> Self { configure { $0.primaryColor = value } }
    func checkColor(_ value: Color) -> Self { configure { $0.checkColor = value } }
}
