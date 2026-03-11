import SwiftUI

// MARK: - RadioGroup

struct AppRadioGroup<T: Hashable>: View {
    @Binding var selection: T
    let options: [(value: T, label: String)]
    var isEnabled: Bool = true
    var size: CGFloat = 16
    var primaryColor: Color = .init(hex: 0x3B82F6)
    var spacing: CGFloat = 8

    init(selection: Binding<T>, options: [(value: T, label: String)]) {
        _selection = selection
        self.options = options
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                AppRadioGroupItem(
                    isSelected: selection == option.value,
                    label: option.label,
                    isEnabled: isEnabled,
                    size: size,
                    primaryColor: primaryColor,
                    action: {
                        selection = option.value
                    }
                )
            }
        }
    }

    // MARK: - Chain Methods

    func disabled(_ value: Bool) -> Self { configure { $0.isEnabled = !value } }
    func size(_ value: CGFloat) -> Self { configure { $0.size = value } }
    func primaryColor(_ value: Color) -> Self { configure { $0.primaryColor = value } }
    func spacing(_ value: CGFloat) -> Self { configure { $0.spacing = value } }
}

// MARK: - RadioGroupItem

struct AppRadioGroupItem: View {
    let isSelected: Bool
    let label: String
    var isEnabled: Bool = true
    var size: CGFloat = 16
    var primaryColor: Color = .init(hex: 0x3B82F6)
    let action: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .strokeBorder(circleColor, lineWidth: 1)
                    .background(Circle().fill(Color.clear))
                    .frame(width: size, height: size)
                    .shadow(color: shadowColor, radius: 2, x: 0, y: 1)

                if isSelected {
                    Circle()
                        .fill(circleColor)
                        .frame(width: indicatorSize, height: indicatorSize)
                }
            }

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.primary)

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isEnabled {
                action()
            }
        }
        .allowsHitTesting(isEnabled)
    }

    private var indicatorSize: CGFloat { size * 0.5 }
    private var shadowColor: Color { Color.black.opacity(0.1) }
    private var circleColor: Color {
        isEnabled ? primaryColor : primaryColor.opacity(0.5)
    }
}
