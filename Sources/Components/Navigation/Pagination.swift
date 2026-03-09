import SwiftUI

// MARK: - Pagination

struct AppPagination: View {
    @Binding var currentPage: Int
    let totalPages: Int
    var onPageChange: ((Int) -> Void)?
    var buttonSize: CGFloat = 36
    var fontSize: CGFloat = 14
    var cornerRadius: CGFloat = 6
    var activeBackgroundColor: Color = Color(.systemBackground)
    var activeBorderColor: Color = .gray.opacity(0.2)
    var hoverColor: Color = Color(hsl: 0, 0, 0.961)

    init(currentPage: Binding<Int>, totalPages: Int) {
        _currentPage = currentPage
        self.totalPages = totalPages
    }

    var body: some View {
        HStack(spacing: 4) {
            AppPaginationPrevious {
                if currentPage > 1 {
                    currentPage -= 1
                    onPageChange?(currentPage)
                }
            }
            .disabled(currentPage <= 1)

            ForEach(Array(visiblePages.enumerated()), id: \.offset) { index, page in
                if page < 0 {
                    AppPaginationEllipsis()
                } else {
                    AppPaginationLink(
                        page: page,
                        isActive: currentPage == page,
                        buttonSize: buttonSize,
                        fontSize: fontSize,
                        cornerRadius: cornerRadius,
                        activeBackgroundColor: activeBackgroundColor,
                        activeBorderColor: activeBorderColor,
                        hoverColor: hoverColor
                    ) {
                        currentPage = page
                        onPageChange?(page)
                    }
                }
            }

            AppPaginationNext {
                if currentPage < totalPages {
                    currentPage += 1
                    onPageChange?(currentPage)
                }
            }
            .disabled(currentPage >= totalPages)
        }
    }

    private var visiblePages: [Int] {
        if totalPages <= 7 { return Array(1 ... totalPages) }
        if currentPage <= 3 { return [1, 2, 3, 4, -1, totalPages] }
        if currentPage >= totalPages - 2 { return [1, -1, totalPages - 3, totalPages - 2, totalPages - 1, totalPages] }
        return [1, -1, currentPage - 1, currentPage, currentPage + 1, -1, totalPages]
    }

    func onPageChange(_ handler: @escaping (Int) -> Void) -> Self {
        configure { $0.onPageChange = handler }
    }

    func buttonSize(_ value: CGFloat) -> Self {
        configure { $0.buttonSize = value }
    }

    func fontSize(_ value: CGFloat) -> Self {
        configure { $0.fontSize = value }
    }

    func cornerRadius(_ value: CGFloat) -> Self {
        configure { $0.cornerRadius = value }
    }

    func hoverColor(_ value: Color) -> Self {
        configure { $0.hoverColor = value }
    }
}

// MARK: - PaginationLink

struct AppPaginationLink: View {
    let page: Int
    let isActive: Bool
    var buttonSize: CGFloat = 36
    var fontSize: CGFloat = 14
    var cornerRadius: CGFloat = 6
    var activeBackgroundColor: Color = Color(.systemBackground)
    var activeBorderColor: Color = .gray.opacity(0.2)
    var hoverColor: Color = Color(hsl: 0, 0, 0.961)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(page)")
                .font(.system(size: fontSize, weight: isActive ? .medium : .regular))
                .foregroundColor(.primary)
                .frame(width: buttonSize, height: buttonSize)
        }
        .buttonStyle(PaginationLinkButtonStyle(
            isActive: isActive,
            cornerRadius: cornerRadius,
            activeBackgroundColor: activeBackgroundColor,
            activeBorderColor: activeBorderColor,
            hoverColor: hoverColor
        ))
    }
}

// MARK: - PaginationPrevious

struct AppPaginationPrevious: View {
    let action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            SafeIcon("ChevronLeft", size: 14, color: isDisabled ? .secondary.opacity(0.5) : .primary)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(PaginationNavButtonStyle())
        .disabled(isDisabled)
    }

    func disabled(_ value: Bool) -> Self {
        configure { $0.isDisabled = value }
    }
}

// MARK: - PaginationNext

struct AppPaginationNext: View {
    let action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            SafeIcon("ChevronRight", size: 14, color: isDisabled ? .secondary.opacity(0.5) : .primary)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(PaginationNavButtonStyle())
        .disabled(isDisabled)
    }

    func disabled(_ value: Bool) -> Self {
        configure { $0.isDisabled = value }
    }
}

// MARK: - PaginationEllipsis

struct AppPaginationEllipsis: View {
    var body: some View {
        SafeIcon("MoreHorizontal", size: 14, color: .secondary)
            .frame(width: 36, height: 36)
    }
}

// MARK: - Button Styles

struct PaginationLinkButtonStyle: ButtonStyle {
    let isActive: Bool
    let cornerRadius: CGFloat
    let activeBackgroundColor: Color
    let activeBorderColor: Color
    let hoverColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                isActive
                    ? activeBackgroundColor
                    : (configuration.isPressed ? hoverColor : Color.clear)
            )
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isActive ? activeBorderColor : Color.clear, lineWidth: 1)
            )
    }
}

struct PaginationNavButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(hsl: 0, 0, 0.961) : Color.clear)
            .cornerRadius(6)
    }
}
