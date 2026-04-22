import SwiftUI

struct VirtueCard: View {
    struct Virtue {
        let name: String
        let subtitle: String
        let principles: [String]
        let color: String
    }

    /// 标准页可折叠；首页直接展示「名称 · 行动准则」与编号列表。
    enum Presentation {
        case standard
        case homeHero
    }

    let virtue: Virtue
    var presentation: Presentation = .standard
    var isExpanded: Bool = false
    var onToggle: ((Bool) -> Void)? = nil

    @State private var expanded: Bool = false

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 0) {
                switch presentation {
                case .standard:
                    VirtueHeader(virtue: virtue, accentColor: accentColor)

                    VirtueContent(
                        virtue: virtue,
                        accentColor: accentColor,
                        expanded: expanded,
                        onToggle: toggleExpand
                    )
                case .homeHero:
                    PrinciplesList(
                        title: "\(virtue.name) · 行动准则",
                        principles: virtue.principles,
                        accentColor: accentColor,
                        showsTopDivider: false
                    )
                    .padding(20)
                }
            }
        }
        .background(AppTheme.colors.surface)
        .borderColor(AppTheme.colors.border)
        .cornerRadius(AppTheme.radius.standard)
        .shadow(color: AppTheme.shadow.soft.color, radius: AppTheme.shadow.soft.radius)
        .overlay(TopAccentBar(color: accentColor), alignment: .top)
        .onAppear {
            if presentation == .standard {
                expanded = isExpanded
            }
        }
        .animation(.easeInOut(duration: 0.3), value: expanded)
    }

    private var accentColor: Color {
        VirtueColorParser.color(from: virtue.color) ?? AppTheme.colors.primary
    }

    private func toggleExpand() {
        expanded.toggle()
        onToggle?(expanded)
    }
}

private struct VirtueHeader: View {
    let virtue: VirtueCard.Virtue
    let accentColor: Color

    var body: some View {
        AppCardHeader {
            VStack(alignment: .leading, spacing: 6) {
                Text(virtue.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(accentColor)

                Text(virtue.subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.colors.onSurface)
                    .padding(.top, 8)
            }
        }
        .padding(20)
    }
}

private struct VirtueContent: View {
    let virtue: VirtueCard.Virtue
    let accentColor: Color
    let expanded: Bool
    let onToggle: () -> Void

    var body: some View {
        AppCardContent {
            AppButton(action: onToggle) {
                HStack(spacing: 8) {
                    Text("行动指南")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.colors.onSurface)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    SafeIcon(expanded ? "ChevronUp" : "ChevronDown", size: 18, color: AppTheme.colors.onMuted)
                }
            }
            .variant(ButtonVariant.ghost)
            .cornerRadius(AppTheme.radius.small)

            if expanded {
                PrinciplesList(
                    title: "\(virtue.name) · 行动准则",
                    principles: virtue.principles,
                    accentColor: accentColor
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(top: 0, horizontal: 20, bottom: 20)
        .spacing(14)
    }
}

private struct PrinciplesList: View {
    let title: String
    let principles: [String]
    let accentColor: Color
    var showsTopDivider: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showsTopDivider {
                Divider()
                    .overlay(AppTheme.colors.border)
            }

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.colors.onMuted)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(principles.enumerated()), id: \.offset) { pair in
                    PrincipleRow(
                        index: pair.offset,
                        text: pair.element,
                        accentColor: accentColor
                    )
                }
            }
        }
        .padding(.top, 8)
    }
}

private struct PrincipleRow: View {
    let index: Int
    let text: String
    let accentColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            IndexBadge(number: index + 1, color: accentColor)
                .padding(.top, 2)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.colors.onSurface)
                .lineSpacing(2)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct IndexBadge: View {
    let number: Int
    let color: Color

    var body: some View {
        Text("\(max(1, number))")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(AppTheme.colors.onPrimary)
            .frame(width: 20, height: 20)
            .background(color)
            .clipShape(Circle())
    }
}

private struct TopAccentBar: View {
    let color: Color

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: 3)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.standard, style: .continuous))
            .padding(.top, 0)
            .allowsHitTesting(false)
    }
}

private enum VirtueColorParser {
    static func color(from hslString: String) -> Color? {
        let trimmed = hslString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        let parts = trimmed
            .replacingOccurrences(of: "%", with: "")
            .split(whereSeparator: { $0 == " " || $0 == "," })
            .map { String($0) }

        guard parts.count >= 3 else { return nil }
        guard let h = Double(parts[0]),
              let s = Double(parts[1]),
              let l = Double(parts[2]) else { return nil }

        let s01 = max(0.0, min(1.0, s / 100.0))
        let l01 = max(0.0, min(1.0, l / 100.0))
        return Color(hsl: h, s01, l01)
    }
}