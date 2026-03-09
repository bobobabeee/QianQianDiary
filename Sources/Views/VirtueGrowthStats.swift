import SwiftUI

struct VirtueGrowthStats: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = VirtueGrowthStatsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            MobileHeader(title: "美德成长回顾", showBack: false)

            ScrollView {
                VStack(spacing: 24) {
                    VirtueGrowthStatsOverviewGrid(
                        totalText: viewModel.totalPracticesText,
                        coveredText: viewModel.virtuesCoveredText,
                        consecutiveText: viewModel.consecutiveDaysText,
                        isEnabled: viewModel.isContentReady
                    )

                    VirtueGrowthStatsTodayVirtueCard(
                        definition: viewModel.todayVirtueDefinition,
                        log: viewModel.todayPracticeLog,
                        onTapRecord: { router.navigate(to: AppRouter.Destination.virtueLogEditor, style: AppRouter.NavigationStyle.push) }
                    )

                    VirtueGrowthStatsTabs(
                        selection: $viewModel.selectedTab,
                        onNavigateSuccessStats: { router.navigate(to: AppRouter.Destination.successDiaryStats) }
                    )

                    VirtueGrowthStatsTabBody(
                        selection: viewModel.selectedTab,
                        isEnabled: viewModel.isContentReady,
                        distributionSlices: viewModel.distributionSlices,
                        timelineGroups: viewModel.timelineGroups,
                        virtueName: viewModel.virtueName(for:),
                        virtueIcon: viewModel.virtueIconName(for:)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 80)
                .frame(maxWidth: 384)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(AppTheme.colors.background)
        }
        .background(AppTheme.colors.background)
        .safeAreaInset(edge: .bottom) {
            MobileBottomNav(activeDestination: AppRouter.Destination.virtueGrowthStats)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { viewModel.onAppear() }
    }
}

private struct VirtueGrowthStatsTabs: View {
    @Binding var selection: VirtueGrowthStatsViewModel.VirtueGrowthStatsTab
    let onNavigateSuccessStats: () -> Void

    var body: some View {
        AppTabs(selection: $selection) {
            AppTabsList(
                selection: $selection,
                tabs: [
                    (value: VirtueGrowthStatsViewModel.VirtueGrowthStatsTab.virtue, label: "美德统计"),
                    (value: VirtueGrowthStatsViewModel.VirtueGrowthStatsTab.success, label: "成功分析")
                ]
            )
            .activeColor(AppTheme.colors.primary)
            .inactiveColor(AppTheme.colors.onMuted)
            .activeBackgroundColor(AppTheme.colors.surface)
            .listBackgroundColor(AppTheme.colors.muted.opacity(0.7))
            .shadowColor(.black.opacity(0.08))
            .height(40)
            .cornerRadius(item: AppTheme.radius.small, list: AppTheme.radius.standard)

            AppTabsContent(value: VirtueGrowthStatsViewModel.VirtueGrowthStatsTab.success, selection: $selection) {
                VirtueGrowthStatsSuccessPlaceholder(onNavigateSuccessStats: onNavigateSuccessStats)
                    .padding(.top, 24)
            }

            AppTabsContent(value: VirtueGrowthStatsViewModel.VirtueGrowthStatsTab.virtue, selection: $selection) {
                Color.clear
                    .frame(height: 0)
            }
        }
        .spacing(24)
    }
}

private struct VirtueGrowthStatsTabBody: View {
    let selection: VirtueGrowthStatsViewModel.VirtueGrowthStatsTab
    let isEnabled: Bool
    let distributionSlices: [VirtueGrowthStatsViewModel.VirtueGrowthStatsDistributionSlice]
    let timelineGroups: [VirtueGrowthStatsViewModel.VirtueGrowthStatsTimelineGroup]
    let virtueName: (VirtueTypeData) -> String
    let virtueIcon: (VirtueTypeData) -> String

    var body: some View {
        Group {
            if selection == VirtueGrowthStatsViewModel.VirtueGrowthStatsTab.virtue {
                VStack(spacing: 24) {
                    VirtueGrowthStatsDistributionCard(
                        isEnabled: isEnabled,
                        slices: distributionSlices
                    )

                    VirtueGrowthStatsTimelineCard(
                        isEnabled: isEnabled,
                        groups: timelineGroups,
                        virtueName: virtueName,
                        virtueIcon: virtueIcon
                    )
                }
                .padding(.top, 24)
            } else {
                EmptyView()
            }
        }
    }
}

private struct VirtueGrowthStatsOverviewGrid: View {
    let totalText: String
    let coveredText: String
    let consecutiveText: String
    let isEnabled: Bool

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

        LazyVGrid(columns: columns, spacing: 12) {
            VirtueGrowthStatsMiniStatCard(
                title: "总践行次数",
                value: totalText,
                icon: "Heart",
                valueSuffix: nil,
                isEnabled: isEnabled
            )

            VirtueGrowthStatsMiniStatCard(
                title: "已覆盖美德",
                value: coveredText,
                icon: "Sparkles",
                valueSuffix: nil,
                isEnabled: isEnabled
            )

            VirtueGrowthStatsMiniStatCard(
                title: "连续践行",
                value: consecutiveText,
                icon: "Flame",
                valueSuffix: nil,
                isEnabled: isEnabled
            )
        }
    }
}

private struct VirtueGrowthStatsTodayVirtueCard: View {
    private let donutImageUrl = "https://spark-builder.s3.cn-north-1.amazonaws.com.cn/image/2026/3/4/a5c896d8-7399-4f5e-9893-a285aeac0d94.png"

    let definition: VirtueDefinitionData
    let log: VirtuePracticeLogData
    let onTapRecord: () -> Void

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    RemoteImage.fixed(url: donutImageUrl, width: 48, height: 48)
                        .contentMode(RemoteImageContentMode.fill)
                        .cornerRadius(24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("今日践行")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.colors.onMuted)
                            .lineLimit(1)

                        Text(definition.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.colors.onSurface)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                    if log.isCompleted {
                        AppBadge("已践行")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

                if log.isCompleted && !log.reflection.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("践行心得")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.colors.onMuted)
                            .lineLimit(1)

                        Text(log.reflection)
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.colors.onSurface)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                } else {
                    VStack(spacing: 12) {
                        Text("记录今日的践行心得，加深对美德的理解")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.colors.onMuted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        AppButton("去记录心得", action: onTapRecord)
                            .variant(ButtonVariant.outline)
                            .size(ButtonSize.small)
                            .foregroundColor(AppTheme.colors.primary)
                            .cornerRadius(AppTheme.radius.small)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(AppTheme.colors.surface)
        .borderColor(AppTheme.colors.border)
        .cornerRadius(AppTheme.radius.standard)
        .shadow(color: AppTheme.shadow.soft.color, radius: AppTheme.shadow.soft.radius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("今日践行 \(definition.name)"))
    }
}

private struct VirtueGrowthStatsMiniStatCard: View {
    let title: String
    let value: String
    let icon: String
    let valueSuffix: String?
    let isEnabled: Bool

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.colors.onMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(minWidth: 0, alignment: .leading)

                    Spacer(minLength: 8)

                    SafeIcon(icon, size: 16, color: AppTheme.colors.primary)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(value)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.colors.onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if let valueSuffix, !valueSuffix.isEmpty {
                        Text(valueSuffix)
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.colors.onMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(AppTheme.colors.surface)
        .borderColor(AppTheme.colors.border)
        .cornerRadius(AppTheme.radius.standard)
        .shadow(color: AppTheme.shadow.soft.color, radius: AppTheme.shadow.soft.radius)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}

private struct VirtueGrowthStatsDistributionCard: View {
    let isEnabled: Bool
    let slices: [VirtueGrowthStatsViewModel.VirtueGrowthStatsDistributionSlice]

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 0) {
                VirtueGrowthStatsCardHeader(
                    title: "美德分布",
                    subtitle: "各美德的覆盖比例"
                )

                AppCardContent {
                    VStack(spacing: 16) {
                        VirtueGrowthStatsDonutChart(slices: slices)
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)

                        if !slices.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(slices.indices, id: \.self) { idx in
                                    VirtueGrowthStatsDistributionRow(slice: slices[idx])
                                }
                            }
                        } else {
                            Text("暂无美德践行记录")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.colors.onMuted)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 24)
                        }
                    }
                }
                .padding(top: 0, horizontal: 24, bottom: 24)
                .spacing(16)
            }
        }
        .background(AppTheme.colors.surface)
        .borderColor(AppTheme.colors.border)
        .cornerRadius(AppTheme.radius.standard)
        .shadow(color: AppTheme.shadow.soft.color, radius: AppTheme.shadow.soft.radius)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}

private struct VirtueGrowthStatsDonutChart: View {
    let slices: [VirtueGrowthStatsViewModel.VirtueGrowthStatsDistributionSlice]

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let radius = size * 0.35
            let innerRadius = size * 0.20

            ZStack {
                AppTheme.colors.background

                ForEach(slices.indices, id: \.self) { idx in
                    VirtueGrowthStatsDonutSlice(
                        startAngle: slices[idx].startAngle,
                        endAngle: slices[idx].endAngle,
                        radius: radius
                    )
                    .fill(slices[idx].color)
                }

                Circle()
                    .fill(AppTheme.colors.background)
                    .frame(width: innerRadius * 2, height: innerRadius * 2)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .cornerRadius(AppTheme.radius.standard)
            .clipped()
        }
    }
}

private struct VirtueGrowthStatsDonutSlice: Shape {
    let startAngle: Double
    let endAngle: Double
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let start = Angle(degrees: startAngle - 90)
        let end = Angle(degrees: endAngle - 90)

        var p = Path()
        p.move(to: center)
        p.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        p.closeSubpath()
        return p
    }
}

private struct VirtueGrowthStatsDistributionRow: View {
    let slice: VirtueGrowthStatsViewModel.VirtueGrowthStatsDistributionSlice

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(slice.color)
                .frame(width: 12, height: 12)

            Text(slice.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.colors.onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(minWidth: 0, alignment: .leading)

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(slice.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.colors.onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(slice.percentageText)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.colors.onMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(8)
        .background(AppTheme.colors.muted.opacity(0.5))
        .cornerRadius(AppTheme.radius.small)
    }
}

private struct VirtueGrowthStatsTimelineCard: View {
    let isEnabled: Bool
    let groups: [VirtueGrowthStatsViewModel.VirtueGrowthStatsTimelineGroup]
    let virtueName: (VirtueTypeData) -> String
    let virtueIcon: (VirtueTypeData) -> String

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 0) {
                VirtueGrowthStatsCardHeader(
                    title: "践行记录",
                    subtitle: "最近的美德践行足迹"
                )

                AppCardContent {
                    if groups.isEmpty {
                        VirtueGrowthStatsTimelineEmpty()
                    } else {
                        VStack(spacing: 16) {
                            ForEach(groups.indices, id: \.self) { idx in
                                VirtueGrowthStatsTimelineGroupView(
                                    group: groups[idx],
                                    virtueName: virtueName,
                                    virtueIcon: virtueIcon
                                )
                            }
                        }
                    }
                }
                .padding(top: 0, horizontal: 24, bottom: 24)
                .spacing(16)
            }
        }
        .background(AppTheme.colors.surface)
        .borderColor(AppTheme.colors.border)
        .cornerRadius(AppTheme.radius.standard)
        .shadow(color: AppTheme.shadow.soft.color, radius: AppTheme.shadow.soft.radius)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}

private struct VirtueGrowthStatsTimelineGroupView: View {
    let group: VirtueGrowthStatsViewModel.VirtueGrowthStatsTimelineGroup
    let virtueName: (VirtueTypeData) -> String
    let virtueIcon: (VirtueTypeData) -> String

    var body: some View {
        VStack(spacing: 8) {
            VirtueGrowthStatsDateDivider(text: group.displayDate)

            VStack(spacing: 8) {
                ForEach(group.logs) { log in
                    VirtueGrowthStatsTimelineLogRow(
                        iconName: virtueIcon(log.virtueType),
                        virtueName: virtueName(log.virtueType),
                        reflection: log.reflection
                    )
                }
            }
        }
    }
}

private struct VirtueGrowthStatsDateDivider: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(AppTheme.colors.border)
                .frame(height: 1)

            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.colors.onMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 8)

            Rectangle()
                .fill(AppTheme.colors.border)
                .frame(height: 1)
        }
    }
}

private struct VirtueGrowthStatsTimelineLogRow: View {
    let iconName: String
    let virtueName: String
    let reflection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                HStack(spacing: 8) {
                    SafeIcon(iconName, size: 16, color: AppTheme.colors.primary)
                        .accessibilityHidden(true)

                    Text(virtueName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.colors.onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(minWidth: 0, alignment: .leading)

                Spacer(minLength: 8)

                AppBadge("已践行")
                    .variant(.secondary)
                    .font(size: 12, weight: .semibold)
                    .background(AppTheme.colors.secondary.opacity(0.25))
                    .textColor(AppTheme.colors.onSecondary)
                    .cornerRadius(6)
            }

            if !reflection.isEmpty {
                Text(reflection)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.colors.onMuted)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(AppTheme.colors.muted.opacity(0.5))
        .cornerRadius(AppTheme.radius.standard)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radius.standard, style: .continuous)
                .stroke(AppTheme.colors.border.opacity(0.5), lineWidth: 1)
        )
    }
}

private struct VirtueGrowthStatsTimelineEmpty: View {
    var body: some View {
        VStack(spacing: 0) {
            SafeIcon("Heart", size: 32, color: AppTheme.colors.onMuted.opacity(0.8))
                .padding(.bottom, 8)
                .opacity(0.7)

            Text("暂无美德践行记录")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.colors.onMuted)
                .padding(.bottom, 4)

            Text("开始记录你的美德践行之旅吧")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.colors.onMuted)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 32)
    }
}

private struct VirtueGrowthStatsSuccessPlaceholder: View {
    let onNavigateSuccessStats: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("成功日记统计功能")
                .font(.system(size: 16))
                .foregroundColor(AppTheme.colors.onMuted)
                .padding(.bottom, 8)

            Button(action: onNavigateSuccessStats) {
                Text("点击查看成功统计中心 →")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.colors.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("点击查看成功统计中心"))
        }
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .center)
        .padding(.vertical, 48)
    }
}

private struct VirtueGrowthStatsCardHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        AppCardHeader {
            VStack(alignment: .leading, spacing: 6) {
                AppCardTitle(title)
                    .font(size: 16, weight: .semibold)
                    .textColor(AppTheme.colors.onSurface)

                AppCardDescription(subtitle)
                    .fontSize(14)
                    .textColor(AppTheme.colors.onMuted)
            }
        }
        .padding(24)
        .spacing(6)
    }
}