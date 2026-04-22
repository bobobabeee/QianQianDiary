import SwiftUI

struct Home: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        VStack(spacing: 0) {
            MobileHeader(
                title: "闪光时刻",
                showBack: false,
                actionIcon: "gearshape.fill",
                actionLabel: "设置",
                onAction: { router.navigate(to: AppRouter.Destination.settings, style: AppRouter.NavigationStyle.push) }
            )

            ScrollView {
                VStack(spacing: AppTheme.spacing.sectionVertical) {
                    HomeHeroSectionView(
                        todayText: viewModel.todayText,
                        heroMessage: viewModel.heroMessage,
                        onQuickRecord: { router.navigate(to: AppRouter.Destination.successDiaryEditor(), style: AppRouter.NavigationStyle.push) },
                        onViewStats: { router.navigate(to: AppRouter.Destination.successDiaryStats, style: AppRouter.NavigationStyle.push) }
                    )

                    HomeHighlightsSectionView(
                        highlights: viewModel.highlights,
                        onTapItem: { router.navigate(to: AppRouter.Destination.diaryCalendarView(date: $0), style: AppRouter.NavigationStyle.push) },
                        onTapViewAll: { router.navigate(to: AppRouter.Destination.diaryCalendarView(date: nil), style: AppRouter.NavigationStyle.push) },
                        onTapStart: { router.navigate(to: AppRouter.Destination.successDiaryEditor(), style: AppRouter.NavigationStyle.push) }
                    )

                    HomeTodayVirtueSectionView(
                        virtue: viewModel.todayVirtueCardModel,
                        isExpanded: viewModel.todayVirtueExpanded,
                        onToggleExpanded: { viewModel.todayVirtueExpanded = $0 },
                        onMarkCompleted: { router.navigate(to: AppRouter.Destination.virtueLogEditor, style: AppRouter.NavigationStyle.push) },
                        onViewVirtueStats: { router.navigate(to: AppRouter.Destination.virtueGrowthStats, style: AppRouter.NavigationStyle.push) }
                    )

                    HomeVisionBoardPreviewView(
                        cells: viewModel.visionBoardGridCells,
                        onViewAll: { router.navigate(to: AppRouter.Destination.visionBoardMain, style: AppRouter.NavigationStyle.push) },
                        onTapCell: { cell in
                            if let id = cell.visionItemId {
                                router.navigate(to: AppRouter.Destination.visionBoardEditor(id: id), style: AppRouter.NavigationStyle.push)
                            } else {
                                router.navigate(to: AppRouter.Destination.visionBoardEditor(id: nil), style: AppRouter.NavigationStyle.push)
                            }
                        }
                    )
                }
                .padding(.horizontal, AppTheme.spacing.screenHorizontal)
                .padding(.vertical, AppTheme.spacing.lg)
                .frame(maxWidth: AppTheme.spacing.contentMaxWidth)
                .frame(maxWidth: .infinity)
            }
            .background(AppTheme.colors.background)
        }
        .safeAreaInset(edge: .bottom) {
            MobileBottomNav(activeDestination: AppRouter.Destination.home)
        }
        .background(AppTheme.colors.background)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.requestSyncFromAPI {
                viewModel.objectWillChange.send()
                print("[HomeView] 首页数据已刷新（含愿景板预览）")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .appShouldSyncData)) { _ in
            viewModel.requestSyncFromAPI {
                viewModel.objectWillChange.send()
            }
        }
    }
}

private struct HomeHeroSectionView: View {
    let todayText: String
    let heroMessage: String
    let onQuickRecord: () -> Void
    let onViewStats: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.spacing.lg) {
            WelcomeCard(todayText: todayText, heroMessage: heroMessage)

            LazyVGrid(columns: columns, spacing: AppTheme.spacing.sm) {
                ActionTile(
                    icon: "Plus",
                    title: "记录成功",
                    variant: HomeActionTileVariant.primary,
                    action: onQuickRecord
                )
                ActionTile(
                    icon: "BarChart3",
                    title: "统计",
                    variant: HomeActionTileVariant.outline,
                    action: onViewStats
                )
            }
        }
    }

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }
}

private struct WelcomeCard: View {
    @ObservedObject private var authService = AuthService.shared

    let todayText: String
    let heroMessage: String

    private var welcomeText: String {
        let name = authService.currentPhone
        return name.isEmpty ? "欢迎回来" : "\(name)欢迎回来"
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.spacing.md) {
            Image("home_welcome_puppy")
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.standard, style: .continuous))
                .accessibilityLabel(Text("Poppy"))

            VStack(alignment: .leading, spacing: 4) {
                Text(welcomeText)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.colors.onSurface)

                Text(todayText)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.colors.onMuted)

                Text(heroMessage)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.colors.onSurface)
                    .lineSpacing(2)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppTheme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.colors.primary.opacity(0.12))
        .cornerRadius(AppTheme.radius.standard)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(welcomeText)，\(todayText)，\(heroMessage)"))
    }
}

private enum HomeActionTileVariant {
    case primary
    case outline
}

private struct ActionTile: View {
    let icon: String
    let title: String
    let variant: HomeActionTileVariant
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                SafeIcon(icon, size: 20, color: resolvedIconColor)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(resolvedTitleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(HomePressableCardButtonStyle(
            background: resolvedBackground,
            borderColor: resolvedBorder,
            cornerRadius: AppTheme.radius.standard,
            normalShadow: AppTheme.shadow.soft,
            pressedShadow: AppTheme.shadow.card
        ))
        .frame(maxWidth: .infinity)
    }

    private var resolvedBackground: Color {
        switch variant {
        case HomeActionTileVariant.primary:
            return AppTheme.colors.primary
        case HomeActionTileVariant.outline:
            return AppTheme.colors.surface
        }
    }

    private var resolvedBorder: Color {
        switch variant {
        case HomeActionTileVariant.primary:
            return AppTheme.colors.primary.opacity(0.0)
        case HomeActionTileVariant.outline:
            return AppTheme.colors.border
        }
    }

    private var resolvedTitleColor: Color {
        switch variant {
        case HomeActionTileVariant.primary:
            return AppTheme.colors.onPrimary
        case HomeActionTileVariant.outline:
            return AppTheme.colors.onSurface
        }
    }

    private var resolvedIconColor: Color {
        resolvedTitleColor
    }
}

private struct HomeTodayVirtueSectionView: View {
    private let donutImageUrl = "https://spark-builder.s3.cn-north-1.amazonaws.com.cn/image/2026/3/4/a5c896d8-7399-4f5e-9893-a285aeac0d94.png"

    let virtue: VirtueCard.Virtue
    let isExpanded: Bool
    let onToggleExpanded: (Bool) -> Void
    let onMarkCompleted: () -> Void
    let onViewVirtueStats: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                RemoteImage.fixed(url: donutImageUrl, width: 48, height: 48)
                    .contentMode(RemoteImageContentMode.fill)
                    .cornerRadius(24)

                Text("今日美德践行")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.colors.onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 8)

                AppButton(action: onViewVirtueStats) {
                    HStack(spacing: 4) {
                        SafeIcon("TrendingUp", size: 14, color: AppTheme.colors.onSurface)
                        Text("统计")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.colors.onSurface)
                            .lineLimit(1)
                    }
                }
                .variant(ButtonVariant.ghost)
                .size(ButtonSize.small)
                .contentPadding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                .height(32)
                .cornerRadius(8)
                .accessibilityLabel(Text("成长统计"))
            }

            VirtueCard(
                virtue: virtue,
                presentation: VirtueCard.Presentation.homeHero,
                isExpanded: isExpanded,
                onToggle: onToggleExpanded
            )

            AppButton(action: onMarkCompleted) {
                HStack(spacing: 8) {
                    SafeIcon("CheckCircle2", size: 18, color: AppTheme.colors.onSurface)
                    Text("标记今日已践行")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.colors.onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
            .variant(ButtonVariant.outline)
            .cornerRadius(AppTheme.radius.large)
            .fullWidth()
            .shadow(color: AppTheme.shadow.soft.color, radius: AppTheme.shadow.soft.radius, x: 0, y: 2)
            .accessibilityLabel(Text("标记今日已践行"))
        }
    }
}

private struct HomeHighlightsSectionView: View {
    let highlights: [SuccessDiaryStatsViewModel.SuccessDiaryStatsHighlightItem]
    let onTapItem: (String) -> Void
    let onTapViewAll: () -> Void
    let onTapStart: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HeaderRow(
                title: "高光时刻",
                trailingTitle: "查看全部",
                trailingIcon: "ChevronRight",
                onTrailingTap: onTapViewAll
            )

            AppCard {
                VStack(alignment: .leading, spacing: 0) {
                    if highlights.isEmpty {
                        VStack(spacing: 0) {
                            SafeIcon("BookOpen", size: 32, color: AppTheme.colors.onMuted.opacity(0.50))
                                .padding(.bottom, 8)
                            Text("暂无记录")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.colors.onMuted)
                            AppButton("开始记录", action: onTapStart)
                                .variant(ButtonVariant.ghost)
                                .size(ButtonSize.small)
                                .foregroundColor(AppTheme.colors.onSurface)
                                .cornerRadius(AppTheme.radius.small)
                                .padding(.top, 12)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(highlights.enumerated()), id: \.offset) { pair in
                                HomeHighlightRowView(
                                    item: pair.element,
                                    showDivider: pair.offset < max(0, highlights.count - 1),
                                    onTap: { onTapItem(pair.element.date) }
                                )
                            }
                            AppButton(action: onTapViewAll) {
                                HStack(spacing: 8) {
                                    SafeIcon("ArrowRight", size: 16, color: AppTheme.colors.onSurface)
                                    Text("查看全部记录")
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                            .variant(ButtonVariant.ghost)
                            .foregroundColor(AppTheme.colors.onSurface)
                            .cornerRadius(AppTheme.radius.small)
                            .fullWidth()
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .background(AppTheme.colors.surface)
            .borderColor(AppTheme.colors.border)
            .cornerRadius(AppTheme.radius.standard)
            .shadow(color: AppTheme.shadow.soft.color, radius: AppTheme.shadow.soft.radius)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("高光时刻"))
        }
    }
}

private struct HomeHighlightRowView: View {
    let item: SuccessDiaryStatsViewModel.SuccessDiaryStatsHighlightItem
    let showDivider: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppTheme.radius.standard, style: .continuous)
                            .fill(item.categoryColor)
                            .frame(width: 40, height: 40)
                        SafeIcon(item.moodIcon, size: 18, color: AppTheme.colors.onPrimary)
                    }
                    .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top, spacing: 8) {
                            Text(item.content)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.colors.onSurface)
                                .lineLimit(2)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            Text(item.displayDate)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.colors.onMuted)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        Text(item.categoryLabel)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.colors.onMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                if showDivider {
                    Divider()
                        .overlay(AppTheme.colors.border)
                        .padding(.top, 12)
                }
            }
            .padding(.bottom, showDivider ? 12 : 0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(item.content))
        .accessibilityValue(Text("\(item.displayDate)，\(item.categoryLabel)"))
    }
}

private struct HomeVisionBoardPreviewView: View {
    let cells: [HomeVisionBoardGridCell]
    let onViewAll: () -> Void
    let onTapCell: (HomeVisionBoardGridCell) -> Void

    var body: some View {
        VStack(spacing: 12) {
            HeaderRow(
                title: "我的愿景板",
                trailingTitle: "查看全部",
                trailingIcon: "ChevronRight",
                onTrailingTap: onViewAll
            )

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(cells) { cell in
                    VisionPreviewTile(
                        title: cell.title,
                        imageUrl: cell.imageUrl,
                        isPlaceholder: cell.visionItemId == nil,
                        onTap: { onTapCell(cell) }
                    )
                }
            }
        }
    }

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }
}

private struct HeaderRow: View {
    let title: String
    let trailingTitle: String
    let trailingIcon: String
    let onTrailingTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.colors.onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(minWidth: 0, alignment: .leading)

            Spacer(minLength: 12)

            AppButton(action: onTrailingTap) {
                HStack(spacing: 4) {
                    Text(trailingTitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.colors.onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    SafeIcon(trailingIcon, size: 14, color: AppTheme.colors.onSurface)
                }
            }
            .variant(ButtonVariant.ghost)
            .size(ButtonSize.small)
            .contentPadding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
            .height(32)
            .cornerRadius(8)
            .accessibilityLabel(Text(trailingTitle))
        }
    }
}

private struct VisionPreviewTile: View {
    let title: String
    let imageUrl: String
    var isPlaceholder: Bool = false
    let onTap: () -> Void

    private var resolvedImageSource: String {
        let t = imageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty || isPlaceholder {
            // 首页预览现在也优先使用后端返回的图片，空时使用默认
            switch title {
            case "成为更好的自己", "成为更好的自己 ", "坚持阅读与记录", "坚持阅读与记录 ":
                return "asset:vision_work"
            case "规律运动", "规律运动 ":
                return "asset:vision_health"
            case "珍惜身边人", "珍惜身边人 ":
                return "asset:vision_relationship"
            default:
                return "asset:vision_growth"
            }
        }
        return t
    }

    var body: some View {
        Button(action: onTap) {
            AppCard {
                VStack(spacing: 0) {
                    // 从后端请求来的图片优先（http URL），回退到本地 asset
                    VisionImage.card(urlOrAsset: resolvedImageSource, aspectRatio: 1.0)
                        .contentMode(RemoteImageContentMode.fill)
                        .placeholder(AppTheme.colors.muted)

                    // 标题区域（纯白色背景，无渐变叠加）
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.colors.onSurface)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                }
            }
            .background(AppTheme.colors.surface)
            .borderColor(AppTheme.colors.border)
            .cornerRadius(AppTheme.radius.standard)
            .shadow(color: AppTheme.shadow.soft.color, radius: AppTheme.shadow.soft.radius, x: 0, y: 2)
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}

private struct HomePressableCardButtonStyle: ButtonStyle {
    let background: Color
    let borderColor: Color
    let cornerRadius: CGFloat
    let normalShadow: (color: Color, radius: Double, x: Double, y: Double)
    let pressedShadow: (color: Color, radius: Double, x: Double, y: Double)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(background, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor.opacity(0.7), lineWidth: 1)
            )
            .shadow(
                color: (configuration.isPressed ? pressedShadow.color : normalShadow.color),
                radius: (configuration.isPressed ? pressedShadow.radius : normalShadow.radius),
                x: (configuration.isPressed ? pressedShadow.x : normalShadow.x),
                y: (configuration.isPressed ? pressedShadow.y : normalShadow.y)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
