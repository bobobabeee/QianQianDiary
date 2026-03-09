import SwiftUI

// MARK: - Table

struct AppTable<Content: View>: View {
    let content: Content
    var fontSize: CGFloat = 14
    var background: AnyShapeStyle = AnyShapeStyle(Color.clear)

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) { content }
        }
        .background(background)
    }

    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
}

// MARK: - Table Header

struct AppTableHeader<Content: View>: View {
    let content: Content
    var background: AnyShapeStyle = AnyShapeStyle(Color(UIColor.secondarySystemBackground))
    var borderColor: Color = .gray.opacity(0.2)

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 0) { content }
            .background(background)
            .overlay(Rectangle().frame(height: 1).foregroundColor(borderColor), alignment: .bottom)
    }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }
}

extension AppTableHeader where Content == EmptyView {
    init() {
        self.content = EmptyView()
    }
}

// MARK: - Table Body

struct AppTableBody<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) { content }
    }
}

// MARK: - Table Footer

struct AppTableFooter<Content: View>: View {
    let content: Content
    var background: AnyShapeStyle = AnyShapeStyle(Color(UIColor.secondarySystemBackground).opacity(0.5))
    var borderColor: Color = .gray.opacity(0.2)

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 0) { content }
            .background(background)
            .overlay(Rectangle().frame(height: 1).foregroundColor(borderColor), alignment: .top)
    }
    func background<S: ShapeStyle>(_ style: S) -> Self { configure { $0.background = AnyShapeStyle(style) } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }
}

extension AppTableFooter where Content == EmptyView {
    init() {
        self.content = EmptyView()
    }
}

// MARK: - Table Row

struct AppTableRow<Content: View>: View {
    let content: Content
    var isSelected: Bool = false
    var borderColor: Color = .gray.opacity(0.2)
    var selectedColor: Color = .init(UIColor.secondarySystemBackground)
    var isLastRow: Bool = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 0) { content }
            .background(isSelected ? selectedColor : Color.clear)
            .overlay(
                Group {
                    if !isLastRow { Rectangle().frame(height: 1).foregroundColor(borderColor) }
                },
                alignment: .bottom
            )
    }

    func selected(_ value: Bool) -> Self { configure { $0.isSelected = value } }
    func lastRow(_ value: Bool) -> Self { configure { $0.isLastRow = value } }
    func borderColor(_ value: Color) -> Self { configure { $0.borderColor = value } }
    func selectedColor(_ value: Color) -> Self { configure { $0.selectedColor = value } }
}

// MARK: - Table Head

struct AppTableHead: View {
    let text: String
    var width: CGFloat?
    var height: CGFloat = 40
    var fontSize: CGFloat = 14
    var fontWeight: Font.Weight = .medium
    var textColor: Color = .secondary
    var horizontalPadding: CGFloat = 8
    var alignment: Alignment = .leading

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundColor(textColor)
            .padding(.horizontal, horizontalPadding)
            .frame(height: height)
            .frame(width: width, alignment: alignment)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: alignment)
    }

    func width(_ value: CGFloat?) -> Self { configure { $0.width = value } }
    func height(_ value: CGFloat) -> Self { configure { $0.height = value } }

    func font(size: CGFloat, weight: Font.Weight = .medium) -> Self {
        configure { $0.fontSize = size; $0.fontWeight = weight }
    }

    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func alignment(_ value: Alignment) -> Self { configure { $0.alignment = value } }
}

// MARK: - Table Cell

struct AppTableCell<Content: View>: View {
    let content: Content
    var width: CGFloat?
    var fontSize: CGFloat = 14
    var textColor: Color = .primary
    var horizontalPadding: CGFloat = 8
    var verticalPadding: CGFloat = 8
    var alignment: Alignment = .leading

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack {
            content.font(.system(size: fontSize)).foregroundColor(textColor)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(width: width, alignment: alignment)
        .frame(maxWidth: width == nil ? .infinity : nil, alignment: alignment)
    }

    func width(_ value: CGFloat?) -> Self { configure { $0.width = value } }
    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
    func alignment(_ value: Alignment) -> Self { configure { $0.alignment = value } }
}

extension AppTableCell where Content == Text {
    init(_ text: String) {
        content = Text(text)
    }
}

// MARK: - Table Caption

struct AppTableCaption: View {
    let text: String
    var fontSize: CGFloat = 14
    var textColor: Color = .secondary
    var topPadding: CGFloat = 16

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .foregroundColor(textColor)
            .padding(.top, topPadding)
    }

    func fontSize(_ value: CGFloat) -> Self { configure { $0.fontSize = value } }
    func textColor(_ value: Color) -> Self { configure { $0.textColor = value } }
}
