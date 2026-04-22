import SwiftUI

struct SuccessDiaryStats: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = SuccessDiaryStatsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            MobileHeader(title: "成功统计中心", showBack: false)

            ScrollView {
                VStack(spacing: 24) {
                    SuccessDiaryStatsOverviewSection(items: viewModel.overviewItems)

                    SuccessDiaryStatsCategoryCard(
                        totalText: viewModel.categoryTotalCountText,
                        slices: viewModel.pieSlices,
                        items: viewModel.categoryItems,
                        hintTitle: viewModel.categoryTopHintTitle,
                        hintBody: viewModel.categoryTopHintBody
                    )
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .frame(maxWidth: 384)
                .frame(maxWidth: .infinity)
            }
            .background(AppTheme.colors.background)
        }
        .background(AppTheme.colors.background)
        .safeAreaInset(edge: .bottom) {
            MobileBottomNav(activeDestination: AppRouter.Destination.successDiaryStats)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.loadFromAPI { viewModel.objectWillChange.send() }
        }
    }
}

private struct SuccessDiaryStatsOverviewSection: View {
    let items: [SuccessDiaryStatsViewModel.SuccessDiaryStatsOverviewItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("数据概览")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.colors.onSurface)
                .padding(.horizontal, 8)

            VStack(spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { pair in
                    StatsCard(
                        title: pair.element.title,
                        value: pair.element.valueText,
                        description: pair.element.description,
                        trend: pair.element.trend,
                        trendValue: pair.element.trendValue,
                        icon: pair.element.icon,
                        variant: StatsCard.Variant.default
                    )
                }
            }
        }
    }
}

private struct SuccessDiaryStatsCategoryCard: View {
    let totalText: String
    let slices: [SuccessDiaryStatsViewModel.SuccessDiaryStatsPieSlice]
    let items: [SuccessDiaryStatsViewModel.SuccessDiaryStatsCategoryItem]
    let hintTitle: String
    let hintBody: String

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 0) {
                SuccessDiaryStatsCardHeader(
                    title: "分类分布",
                    subtitle: "成功事件类型占比",
                    icon: "PieChart"
                )
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 16) {
                    SuccessDiaryStatsPieChart(totalText: totalText, slices: slices)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(items.enumerated()), id: \.offset) { pair in
                            SuccessDiaryStatsCategoryLegendRow(item: pair.element)
                        }
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Divider()
                            .overlay(AppTheme.colors.border)
                            .padding(.bottom, 12)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(hintTitle)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.colors.onSurface)

                            Text(hintBody)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.colors.onMuted)
                                .lineSpacing(2)
                        }
                        .padding(12)
                        .background(AppTheme.colors.primary.opacity(0.05))
                        .cornerRadius(AppTheme.radius.standard)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(AppTheme.colors.surface)
        .borderColor(AppTheme.colors.border)
        .cornerRadius(AppTheme.radius.standard)
        .shadow(color: AppTheme.shadow.soft.color, radius: AppTheme.shadow.soft.radius)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("分类分布"))
    }
}

private struct SuccessDiaryStatsPieChart: View {
    let totalText: String
    let slices: [SuccessDiaryStatsViewModel.SuccessDiaryStatsPieSlice]

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.colors.muted.opacity(0.10))

            ForEach(Array(slices.enumerated()), id: \.offset) { pair in
                SuccessDiaryStatsPieSliceShape(
                    startAngle: pair.element.startAngle,
                    endAngle: pair.element.endAngle
                )
                .fill(pair.element.color)
            }

            Circle()
                .fill(AppTheme.colors.background)
                .frame(width: 70, height: 70)

            Text(totalText)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppTheme.colors.onSurface)
        }
        .frame(width: 140, height: 140)
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("分类饼图"))
        .accessibilityValue(Text("总计 \(totalText)"))
    }
}

private struct SuccessDiaryStatsPieSliceShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        var p = Path()
        p.move(to: center)
        p.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        p.closeSubpath()
        return p
    }
}

private struct SuccessDiaryStatsCategoryLegendRow: View {
    let item: SuccessDiaryStatsViewModel.SuccessDiaryStatsCategoryItem

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(item.color)
                    .frame(width: 12, height: 12)

                Text(item.label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.colors.onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(minWidth: 0, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Text("\(max(0, item.count))")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.colors.onMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("\(max(0, item.percentage))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.colors.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(item.label))
        .accessibilityValue(Text("\(max(0, item.count))，\(max(0, item.percentage))%"))
    }
}

private struct SuccessDiaryStatsCardHeader: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.colors.onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.colors.onMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            SafeIcon(icon, size: 20, color: AppTheme.colors.primary)
                .accessibilityHidden(true)
        }
    }
}