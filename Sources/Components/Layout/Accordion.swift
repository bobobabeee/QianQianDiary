import SwiftUI

// MARK: - Accordion Item Data

struct AccordionItemData: Identifiable {
    let id = UUID()
    let title: String
    let content: AnyView

    init(title: String, @ViewBuilder content: () -> some View) {
        self.title = title
        self.content = AnyView(content())
    }
}

// MARK: - Accordion

struct AppAccordion<Content: View>: View {
    let content: Content
    var dividerColor: Color = .init(hex: 0xE5E7EB)

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.bottom, -1)
        .clipped()
    }

    func dividerColor(_ value: Color) -> Self { configure { $0.dividerColor = value } }
}

// MARK: - Accordion Item

struct AppAccordionItem<TriggerContent: View, ItemContent: View>: View {
    @State private var isExpanded: Bool = false
    let trigger: TriggerContent
    let content: ItemContent
    var titleFontSize: CGFloat = 14
    var titleFontWeight: Font.Weight = .medium
    var titleColor: Color = .primary
    var contentFontSize: CGFloat = 14
    var contentColor: Color = .primary
    var iconColor: Color = .secondary
    var dividerColor: Color = .init(hex: 0xE5E7EB)
    var verticalPadding: CGFloat = 16

    init(
        @ViewBuilder trigger: () -> TriggerContent,
        @ViewBuilder content: () -> ItemContent
    ) {
        self.trigger = trigger()
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    trigger
                        .font(.system(size: titleFontSize, weight: titleFontWeight))
                        .foregroundColor(titleColor)

                    Spacer()

                    SafeIcon("ChevronDown", size: 16, color: iconColor)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(.vertical, verticalPadding)
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    content
                        .font(.system(size: contentFontSize))
                        .foregroundColor(contentColor)
                }
                .padding(.bottom, verticalPadding)
                .transition(.opacity)
            }

            Rectangle()
                .fill(dividerColor)
                .frame(height: 1)
        }
    }

    // MARK: - Chain Methods

    func titleFont(size: CGFloat, weight: Font.Weight = .medium) -> Self {
        configure { $0.titleFontSize = size; $0.titleFontWeight = weight }
    }

    func titleColor(_ value: Color) -> Self { configure { $0.titleColor = value } }
    func contentFont(size: CGFloat) -> Self { configure { $0.contentFontSize = size } }
    func contentColor(_ value: Color) -> Self { configure { $0.contentColor = value } }
    func iconColor(_ value: Color) -> Self { configure { $0.iconColor = value } }
    func dividerColor(_ value: Color) -> Self { configure { $0.dividerColor = value } }
    func verticalPadding(_ value: CGFloat) -> Self { configure { $0.verticalPadding = value } }
}
