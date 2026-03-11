import SwiftUI

// MARK: - Field Orientation

enum FieldOrientation {
    case vertical
    case horizontal
}

// MARK: - Field

struct AppField<Content: View>: View {
    let content: Content
    var orientation: FieldOrientation = .vertical
    var spacing: CGFloat = 12
    var horizontalAlignment: VerticalAlignment = .center

    init(
        orientation: FieldOrientation = .vertical,
        spacing: CGFloat = 12,
        horizontalAlignment: VerticalAlignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.orientation = orientation
        self.spacing = spacing
        self.horizontalAlignment = horizontalAlignment
        self.content = content()
    }

    var body: some View {
        Group {
            if orientation == .vertical {
                VStack(alignment: .leading, spacing: spacing) {
                    content
                }
            } else {
                HStack(alignment: horizontalAlignment, spacing: spacing) {
                    content
                }
            }
        }
    }
}

// MARK: - FieldSet

struct AppFieldSet<Content: View>: View {
    let content: Content
    var spacing: CGFloat = 24

    init(
        spacing: CGFloat = 24,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
    }
}

// MARK: - FieldLegend

enum FieldLegendVariant {
    case legend
    case label
}

struct AppFieldLegend: View {
    let text: String
    var variant: FieldLegendVariant = .legend
    var bottomPadding: CGFloat = 12
    var textColor: Color = .primary

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .medium))
            .foregroundColor(textColor)
            .padding(.bottom, bottomPadding)
    }

    private var fontSize: CGFloat {
        variant == .legend ? 16 : 14
    }
}

// MARK: - FieldGroup

struct AppFieldGroup<Content: View>: View {
    let content: Content
    var spacing: CGFloat = 28

    init(
        spacing: CGFloat = 28,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
    }
}

// MARK: - FieldContent

struct AppFieldContent<Content: View>: View {
    let content: Content
    var spacing: CGFloat = 6

    init(
        spacing: CGFloat = 6,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
    }
}

// MARK: - FieldLabel

struct AppFieldLabel: View {
    let text: String
    var fontSize: CGFloat = 14
    var fontWeight: Font.Weight = .medium
    var textColor: Color = .primary
    var isDisabled: Bool = false
    var isRequired: Bool = false
    var requiredColor: Color = .red
    var requiredSpacing: CGFloat = 2

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(spacing: requiredSpacing) {
            Text(text)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(isDisabled ? textColor.opacity(0.5) : textColor)

            if isRequired {
                Text("*")
                    .font(.system(size: fontSize, weight: fontWeight))
                    .foregroundColor(isDisabled ? requiredColor.opacity(0.5) : requiredColor)
            }
        }
    }
}

// MARK: - FieldTitle

struct AppFieldTitle: View {
    let text: String
    var fontSize: CGFloat = 14
    var fontWeight: Font.Weight = .medium
    var textColor: Color = .primary
    var isDisabled: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundColor(isDisabled ? textColor.opacity(0.5) : textColor)
    }
}

// MARK: - FieldDescription

struct AppFieldDescription: View {
    let text: String
    var fontSize: CGFloat = 14
    var textColor: Color = .secondary

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .foregroundColor(textColor)
    }
}

// MARK: - FieldSeparator

struct AppFieldSeparator<Content: View>: View {
    let content: Content?
    var textColor: Color = .secondary
    var separatorColor: Color = .gray.opacity(0.3)
    var fontSize: CGFloat = 14

    init(
        textColor: Color = .secondary,
        separatorColor: Color = .gray.opacity(0.3),
        fontSize: CGFloat = 14,
        @ViewBuilder content: () -> Content
    ) {
        self.textColor = textColor
        self.separatorColor = separatorColor
        self.fontSize = fontSize
        self.content = content()
    }

    var body: some View {
        HStack {
            Rectangle()
                .fill(separatorColor)
                .frame(height: 1)

            if let content {
                content
                    .font(.system(size: fontSize))
                    .foregroundColor(textColor)

                Rectangle()
                    .fill(separatorColor)
                    .frame(height: 1)
            }
        }
        .padding(.vertical, 8)
    }
}

extension AppFieldSeparator where Content == EmptyView {
    init(
        separatorColor: Color = .gray.opacity(0.3)
    ) {
        textColor = .secondary
        self.separatorColor = separatorColor
        fontSize = 14
        content = nil
    }
}

extension AppFieldSeparator where Content == Text {
    init(
        text: String,
        textColor: Color = .secondary,
        separatorColor: Color = .gray.opacity(0.3),
        fontSize: CGFloat = 14
    ) {
        self.textColor = textColor
        self.separatorColor = separatorColor
        self.fontSize = fontSize
        content = Text(text)
    }
}

// MARK: - FieldError

struct AppFieldError: View {
    let message: String?
    var messages: [String]?
    var fontSize: CGFloat = 14
    var textColor: Color = .red

    var body: some View {
        Group {
            if let messages, messages.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(messages, id: \.self) { msg in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                            Text(msg)
                        }
                        .font(.system(size: fontSize))
                        .foregroundColor(textColor)
                    }
                }
            } else if let message = message ?? messages?.first {
                Text(message)
                    .font(.system(size: fontSize))
                    .foregroundColor(textColor)
            }
        }
    }
}
