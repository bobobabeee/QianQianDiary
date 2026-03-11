import SwiftUI

struct DiaryCalendarView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel: DiaryCalendarViewModel

    init(date: String?) {
        _viewModel = StateObject(wrappedValue: DiaryCalendarViewModel(initialDate: date))
    }

    var body: some View {
        VStack(spacing: 0) {
            MobileHeader(
                title: "成功足迹",
                showBack: false,
                actionIcon: "BarChart3",
                actionLabel: "切换至趋势看板",
                onAction: { router.navigate(to: AppRouter.Destination.successDiaryStats, style: AppRouter.NavigationStyle.push) }
            )

            ScrollView {
                VStack(spacing: AppTheme.spacing.sectionVertical) {
                    DiaryCalendarViewCalendarCardView(viewModel: viewModel)
                    DiaryCalendarViewDiaryListSectionView(viewModel: viewModel)
                }
                .padding(.horizontal, AppTheme.spacing.screenHorizontal)
                .padding(.vertical, AppTheme.spacing.lg)
                .frame(maxWidth: AppTheme.spacing.contentMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .background(AppTheme.colors.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            MobileBottomNav(activeDestination: AppRouter.Destination.diaryCalendarView(date: nil))
        }
        .navigationBarBackButtonHidden(true)
    }
}

private struct DiaryCalendarViewCalendarCardView: View {
    @ObservedObject var viewModel: DiaryCalendarViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        AppCard {
            AppCardContent {
                VStack(spacing: 0) {
                    monthNavRow
                        .padding(.bottom, 24)

                    weekHeader
                        .padding(.bottom, 8)

                    dayGrid

                    legendRow
                        .padding(.top, 24)
                }
            }
            .spacing(0)
            .padding(20)
        }
        .background(AppTheme.colors.surface)
        .borderColor(AppTheme.colors.border)
        .cornerRadius(AppTheme.radius.standard)
        .shadow(color: AppTheme.shadow.soft.color, radius: AppTheme.shadow.soft.radius)
    }

    private var monthNavRow: some View {
        HStack(spacing: 0) {
            AppButton(action: { viewModel.goToPreviousMonth() }) {
                SafeIcon("ChevronLeft", size: 18, color: AppTheme.colors.onSurface)
            }
            .variant(ButtonVariant.ghost)
            .size(ButtonSize.icon)
            .height(32)
            .cornerRadius(8)
            .accessibilityLabel(Text("上一个月"))

            Spacer(minLength: 8)

            Text(viewModel.monthLabel)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.colors.onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 8)

            AppButton(action: { viewModel.goToNextMonth() }) {
                SafeIcon("ChevronRight", size: 18, color: AppTheme.colors.onSurface)
            }
            .variant(ButtonVariant.ghost)
            .size(ButtonSize.icon)
            .height(32)
            .cornerRadius(8)
            .accessibilityLabel(Text("下一个月"))
        }
    }

    private var weekHeader: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { label in
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.colors.onMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
    }

    private var dayGrid: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(viewModel.calendarCells.enumerated()), id: \.offset) { pair in
                DiaryCalendarViewDayCellView(
                    cell: pair.element,
                    isSelected: pair.element.map { viewModel.isSelected(dateString: $0.dateString) } ?? false,
                    onSelect: { date in viewModel.selectDate(date) }
                )
            }
        }
    }

    private var legendRow: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(AppTheme.colors.border)
                .padding(.bottom, 16)

            HStack(spacing: 16) {
                legendItem(color: AppTheme.colors.secondary, text: "有记录", usePuppy: true)
                legendItem(color: AppTheme.colors.muted, text: "无记录")
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func legendItem(color: Color, text: String, usePuppy: Bool = false) -> some View {
        HStack(spacing: 8) {
            if usePuppy {
                Image("calendar_puppy_1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(color)
                    .frame(width: 12, height: 12)
            }

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.colors.onMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

/// 根据日期在 1...30 内返回「随机感」但稳定的小狗贴纸序号：同一天始终同一只，不同天分布更随机。
private func calendarPuppyStickerIndex(for dateString: String) -> Int {
    let parts = dateString.split(separator: "-").compactMap { Int($0) }
    guard parts.count >= 3 else { return 1 }
    let (y, m, d) = (parts[0], parts[1], parts[2])
    let seed = y * 372 + m * 31 + d
    let hash = (seed * 7919) % 30
    return (hash + 30) % 30 + 1
}

private struct DiaryCalendarViewDayCellView: View {
    let cell: DiaryCalendarViewCalendarCell?
    let isSelected: Bool
    let onSelect: (String) -> Void

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(backgroundColor)

                if let dayCell = cell {
                    if dayCell.hasRecords {
                        Image("calendar_puppy_\(calendarPuppyStickerIndex(for: dayCell.dateString))")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .padding(4)
                    } else {
                        Text("\(dayCell.day)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(textColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(4)
                    }
                }
            }
            .aspectRatio(1.0, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? AppTheme.colors.primary : Color.clear, lineWidth: isSelected ? 2 : 0)
            )
            .shadow(color: isSelected ? Color.black.opacity(0.12) : Color.clear, radius: isSelected ? 8 : 0, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(cell == nil)
        .accessibilityLabel(Text(accessibilityLabel))
    }

    private var backgroundColor: Color {
        guard cell != nil else { return Color.clear }
        if isSelected { return AppTheme.colors.primary }
        if cell!.hasRecords { return AppTheme.colors.secondary }
        return AppTheme.colors.muted
    }

    private var textColor: Color {
        guard cell != nil else { return Color.clear }
        if isSelected { return AppTheme.colors.onPrimary }
        return AppTheme.colors.onMuted
    }

    private var accessibilityLabel: String {
        guard let c = cell else { return "空白日期" }
        if c.hasRecords {
            return "\(c.day)号，有记录"
        }
        return "\(c.day)号，无记录"
    }

    private func handleTap() {
        guard let c = cell else { return }
        onSelect(c.dateString)
    }
}

private struct DiaryCalendarViewDiaryListSectionView: View {
    @EnvironmentObject private var router: AppRouter
    @ObservedObject var viewModel: DiaryCalendarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.selectedEntries.isEmpty {
                EmptyState(
                    illustration: EmptyState.Illustration.calendarEmpty,
                    customImageUrl: nil,
                    title: "暂无记录",
                    message: "这一天还没有记录成功事件。点击下方按钮添加第一条记录吧！",
                    actionText: "补记日记",
                    actionDestination: AppRouter.Destination.successDiaryEditor,
                    onAction: nil
                )
            } else {
                Text("今日成功记录")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.colors.onMuted)

                VStack(spacing: 12) {
                    ForEach(viewModel.selectedEntries) { entry in
                        DiaryCalendarViewDiaryListCardView(
                            entry: entry,
                            categoryLabel: viewModel.categoryLabel(for: entry.category),
                            onEdit: { router.navigate(to: AppRouter.Destination.successDiaryEditor, style: AppRouter.NavigationStyle.push) },
                            onDelete: { viewModel.deleteEntry(id: entry.id) }
                        )
                    }
                }
            }
        }
    }
}

private struct DiaryCalendarViewDiaryListCardView: View {
    let entry: SuccessDiaryEntryData
    let categoryLabel: String
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isExpanded: Bool = false

    var body: some View {
        AppCard {
            AppCardContent {
                VStack(alignment: .leading, spacing: 12) {
                    headerRow
                    contentBlock
                    actionRow
                }
            }
            .padding(top: 16, horizontal: 24, bottom: 16)
            .spacing(0)
        }
        .background(AppTheme.colors.surface)
        .borderColor(AppTheme.colors.border)
        .cornerRadius(AppTheme.radius.standard)
        .shadow(color: AppTheme.shadow.soft.color, radius: AppTheme.shadow.soft.radius)
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 12) {
            DiaryCalendarViewCategoryChipView(title: categoryLabel, category: entry.category)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            SafeIcon(entry.moodIcon, size: 20, color: moodIconColor)
                .accessibilityHidden(true)
        }
    }

    private var contentBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.content)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.colors.onSurface)
                .lineSpacing(2)
                .lineLimit(isExpanded ? nil : 2)

            if shouldShowExpandButton {
                Button(action: { isExpanded.toggle() }) {
                    Text(isExpanded ? "收起" : "展开")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.colors.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(isExpanded ? "收起内容" : "展开内容"))
            }
        }
    }

    private var actionRow: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(AppTheme.colors.border)
                .padding(.top, 4)

            HStack(spacing: 8) {
                AppButton(action: onEdit) {
                    HStack(spacing: 6) {
                        SafeIcon("Edit2", size: 14, color: AppTheme.colors.onSurface)
                        Text("编辑")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.colors.onSurface)
                    }
                    .frame(maxWidth: .infinity)
                }
                .variant(ButtonVariant.ghost)
                .height(32)
                .cornerRadius(8)

                AppButton(action: onDelete) {
                    HStack(spacing: 6) {
                        SafeIcon("Trash2", size: 14, color: AppTheme.colors.error)
                        Text("删除")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.colors.error)
                    }
                    .frame(maxWidth: .infinity)
                }
                .variant(ButtonVariant.ghost)
                .height(32)
                .cornerRadius(8)
            }
            .padding(.top, 12)
        }
    }

    private var shouldShowExpandButton: Bool {
        entry.content.count > 60
    }

    private var moodIconColor: Color {
        switch entry.moodIcon {
        case "Sun":
            return Color(red: 0.92, green: 0.70, blue: 0.12)
        case "Zap":
            return Color(red: 0.96, green: 0.55, blue: 0.20)
        case "Activity":
            return Color(red: 0.10, green: 0.65, blue: 0.30)
        case "MessageSquareHeart":
            return Color(red: 0.93, green: 0.30, blue: 0.60)
        case "Heart":
            return Color(red: 0.90, green: 0.20, blue: 0.25)
        case "Star":
            return Color(red: 0.55, green: 0.35, blue: 0.90)
        default:
            return AppTheme.colors.primary
        }
    }
}

private struct DiaryCalendarViewCategoryChipView: View {
    let title: String
    let category: DiaryCategoryData

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(background)
            .clipShape(Capsule())
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private var background: Color {
        switch category {
        case DiaryCategoryData.work:
            return Color(red: 0.86, green: 0.92, blue: 1.00)
        case DiaryCategoryData.health:
            return Color(red: 0.88, green: 0.98, blue: 0.90)
        case DiaryCategoryData.relationship:
            return Color(red: 1.00, green: 0.88, blue: 0.94)
        case DiaryCategoryData.growth:
            return Color(red: 0.93, green: 0.88, blue: 1.00)
        case DiaryCategoryData.daily:
            return Color(red: 1.00, green: 0.95, blue: 0.82)
        }
    }

    private var foreground: Color {
        switch category {
        case DiaryCategoryData.work:
            return Color(red: 0.11, green: 0.40, blue: 0.78)
        case DiaryCategoryData.health:
            return Color(red: 0.08, green: 0.55, blue: 0.20)
        case DiaryCategoryData.relationship:
            return Color(red: 0.75, green: 0.16, blue: 0.44)
        case DiaryCategoryData.growth:
            return Color(red: 0.45, green: 0.22, blue: 0.85)
        case DiaryCategoryData.daily:
            return Color(red: 0.70, green: 0.40, blue: 0.05)
        }
    }
}
