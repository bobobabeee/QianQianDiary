import SwiftUI
import Foundation

@MainActor
final class SuccessDiaryStatsViewModel: ObservableObject {
    struct SuccessDiaryStatsOverviewItem {
        let title: String
        let valueText: String
        let description: String
        let icon: String
        let trend: StatsCard.Trend
        let trendValue: String?
    }

    struct SuccessDiaryStatsCategoryItem {
        let category: DiaryCategoryData
        let label: String
        let count: Int
        let percentage: Int
        let color: Color
    }

    struct SuccessDiaryStatsPieSlice {
        let startAngle: Angle
        let endAngle: Angle
        let color: Color
    }

    struct SuccessDiaryStatsHighlightItem {
        let id: String
        let date: String
        let content: String
        let categoryLabel: String
        let moodIcon: String
        let categoryColor: Color
        let displayDate: String
    }

    private let diaryService: DiaryService
    private let calendar: Calendar
    private let locale: Locale

    init(
        diaryService: DiaryService = DiaryService.shared,
        calendar: Calendar = Calendar.current,
        locale: Locale = Locale(identifier: "zh_CN")
    ) {
        self.diaryService = diaryService
        self.calendar = calendar
        self.locale = locale
    }

    func loadFromAPI(completion: @escaping () -> Void) {
        let (startDate, endDate) = currentMonthRange()
        diaryService.fetchStats(startDate: startDate, endDate: endDate) {
            completion()
        }
    }

    var overviewItems: [SuccessDiaryStatsOverviewItem] {
        let stats = diaryService.getStatsSummary()
        return [
            SuccessDiaryStatsOverviewItem(
                title: "总记录数",
                valueText: "\(stats.totalCount)",
                description: "累计成功事件",
                icon: "BookOpen",
                trend: stats.totalCount > 0 ? StatsCard.Trend.up : StatsCard.Trend.neutral,
                trendValue: nil
            ),
            SuccessDiaryStatsOverviewItem(
                title: "本周记录",
                valueText: "\(stats.thisWeekCount)",
                description: "这周的成就",
                icon: "Calendar",
                trend: stats.thisWeekCount > 0 ? StatsCard.Trend.up : StatsCard.Trend.neutral,
                trendValue: stats.thisWeekCount > 0 ? "+\(stats.thisWeekCount) 本周" : nil
            ),
            SuccessDiaryStatsOverviewItem(
                title: "连续天数",
                valueText: "\(stats.streakDays)",
                description: "坚持记录中",
                icon: "Flame",
                trend: stats.streakDays > 0 ? StatsCard.Trend.up : StatsCard.Trend.neutral,
                trendValue: stats.streakDays > 0 ? "+\(stats.streakDays) 天" : nil
            )
        ]
    }

    var categoryItems: [SuccessDiaryStatsCategoryItem] {
        let dist = diaryService.getCategoryDistribution()
        guard !dist.isEmpty else { return [] }

        let total = max(1, dist.reduce(0) { $0 + $1.count })
        let colorMap: [String: Color] = [
            "WORK": AppTheme.colors.chart1,
            "HEALTH": AppTheme.colors.chart2,
            "RELATIONSHIP": AppTheme.colors.chart3,
            "GROWTH": AppTheme.colors.chart4,
            "DAILY": AppTheme.colors.chart5,
        ]
        let fallbackColors: [Color] = [
            AppTheme.colors.chart1, AppTheme.colors.chart2, AppTheme.colors.chart3,
            AppTheme.colors.chart4, AppTheme.colors.chart5,
        ]

        return dist.enumerated().map { idx, item in
            let cat = DiaryCategoryData(rawValue: item.category) ?? .daily
            let pct = (item.count * 100) / total
            let color = colorMap[item.category] ?? fallbackColors[idx % fallbackColors.count]
            return SuccessDiaryStatsCategoryItem(
                category: cat,
                label: item.label.isEmpty ? diaryService.getCategoryLabel(cat) : item.label,
                count: item.count,
                percentage: pct,
                color: color
            )
        }
    }

    var categoryTotalCountText: String {
        let total = categoryItems.reduce(0) { $0 + $1.count }
        return "\(total)"
    }

    var categoryTopHintTitle: String {
        "🌟 高频成功类型"
    }

    var categoryTopHintBody: String {
        let first = categoryItems.max(by: { $0.count < $1.count })
        let label = first?.label ?? "某个类型"
        return "\(label)是你最常记录的成功类型，继续保持这份热情！"
    }

    var pieSlices: [SuccessDiaryStatsPieSlice] {
        let items = categoryItems
        let totalPercent = items.reduce(0) { $0 + $1.percentage }
        let normalizedDenom = max(1, totalPercent)

        var start = -90.0
        var result: [SuccessDiaryStatsPieSlice] = []
        for item in items {
            let delta = (Double(item.percentage) / Double(normalizedDenom)) * 360.0
            let slice = SuccessDiaryStatsPieSlice(
                startAngle: Angle(degrees: start),
                endAngle: Angle(degrees: start + delta),
                color: item.color
            )
            result.append(slice)
            start += delta
        }
        return result
    }

    var highlights: [SuccessDiaryStatsHighlightItem] {
        let entries = diaryService.getEntries(date: nil, category: nil)
        let sorted = entries.sorted { lhs, rhs in
            if lhs.date == rhs.date { return lhs.id > rhs.id }
            return lhs.date > rhs.date
        }
        let top = Array(sorted.prefix(5))

        return top.map { entry in
            SuccessDiaryStatsHighlightItem(
                id: entry.id,
                date: entry.date,
                content: entry.content,
                categoryLabel: diaryService.getCategoryLabel(entry.category),
                moodIcon: entry.moodIcon,
                categoryColor: categoryColor(for: entry.category),
                displayDate: displayDateText(isoDate: entry.date)
            )
        }
    }


    private func categoryColor(for category: DiaryCategoryData) -> Color {
        switch category {
        case DiaryCategoryData.work: return AppTheme.colors.chart1
        case DiaryCategoryData.health: return AppTheme.colors.chart2
        case DiaryCategoryData.relationship: return AppTheme.colors.chart3
        case DiaryCategoryData.growth: return AppTheme.colors.chart4
        case DiaryCategoryData.daily: return AppTheme.colors.chart5
        }
    }

    private func displayDateText(isoDate: String) -> String {
        let today = currentIsoDateString()
        if isoDate == today { return "今天" }

        if let yesterday = isoDateByAddingDays(-1, to: today), isoDate == yesterday {
            return "昨天"
        }

        guard let date = parseIsoDate(isoDate) else { return isoDate }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    private func parseIsoDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }

    private func isoDateByAddingDays(_ days: Int, to iso: String) -> String? {
        guard let date = parseIsoDate(iso) else { return nil }
        guard let updated = calendar.date(byAdding: .day, value: days, to: date) else { return nil }

        let out = DateFormatter()
        out.locale = Locale(identifier: "en_US_POSIX")
        out.calendar = calendar
        out.dateFormat = "yyyy-MM-dd"
        return out.string(from: updated)
    }

    private func currentIsoDateString() -> String {
        let out = DateFormatter()
        out.locale = Locale(identifier: "en_US_POSIX")
        out.calendar = calendar
        out.dateFormat = "yyyy-MM-dd"
        return out.string(from: Date())
    }

    private func currentMonthRange() -> (startDate: String, endDate: String) {
        let now = Date()
        let comps = calendar.dateComponents([.year, .month], from: now)
        let year = comps.year ?? 2026
        let month = comps.month ?? 1
        let startDate = String(format: "%04d-%02d-01", year, month)
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: calendar.date(from: comps) ?? now) ?? now
        let lastDay = calendar.date(byAdding: .day, value: -1, to: nextMonth) ?? now
        let dayOfLastDay = calendar.component(.day, from: lastDay)
        let endDate = String(format: "%04d-%02d-%02d", year, month, dayOfLastDay)
        return (startDate, endDate)
    }
}