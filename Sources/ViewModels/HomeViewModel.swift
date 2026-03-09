import SwiftUI
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var todayVirtueExpanded: Bool = false

    private let virtueService: VirtueService
    private let diaryService: DiaryService
    private let visionService: VisionService
    private let calendar: Calendar

    init(
        virtueService: VirtueService = VirtueService.shared,
        diaryService: DiaryService = DiaryService.shared,
        visionService: VisionService = VisionService.shared,
        calendar: Calendar = Calendar.current
    ) {
        self.virtueService = virtueService
        self.diaryService = diaryService
        self.visionService = visionService
        self.calendar = calendar
    }

    var todayText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: Date())
    }

    var heroMessage: String {
        "每一个小成就都值得被记录。"
    }

    var todayVirtueCardModel: VirtueCard.Virtue {
        let definition = virtueService.getTodayVirtueDefinition(date: Date(), calendar: calendar)
        return VirtueCard.Virtue(
            name: definition.name,
            subtitle: definition.quote,
            principles: definition.guidelines,
            color: colorHslString(for: definition.type)
        )
    }

    var recentDiaries: [SuccessDiaryEntryData] {
        let all = diaryService.getEntries(date: nil, category: nil)
        if all.isEmpty { return [] }
        return Array(all.prefix(3))
    }

    /// 高光时刻：最近 5 条成功记录，与统计页原「高光时刻」一致，用于首页展示。
    var highlights: [SuccessDiaryStatsViewModel.SuccessDiaryStatsHighlightItem] {
        let entries = diaryService.getEntries(date: nil, category: nil)
        let sorted = entries.sorted { lhs, rhs in
            if lhs.date == rhs.date { return lhs.id > rhs.id }
            return lhs.date > rhs.date
        }
        let top = Array(sorted.prefix(5))
        let locale = Locale(identifier: "zh_CN")
        return top.map { entry in
            SuccessDiaryStatsViewModel.SuccessDiaryStatsHighlightItem(
                id: entry.id,
                date: entry.date,
                content: entry.content,
                categoryLabel: diaryService.getCategoryLabel(entry.category),
                moodIcon: entry.moodIcon,
                categoryColor: highlightCategoryColor(for: entry.category),
                displayDate: highlightDisplayDate(isoDate: entry.date, locale: locale)
            )
        }
    }

    private func highlightCategoryColor(for category: DiaryCategoryData) -> Color {
        switch category {
        case .work: return AppTheme.colors.chart1
        case .health: return AppTheme.colors.chart2
        case .relationship: return AppTheme.colors.chart3
        case .growth: return AppTheme.colors.chart4
        case .daily: return AppTheme.colors.chart5
        }
    }

    private func highlightDisplayDate(isoDate: String, locale: Locale) -> String {
        let today = highlightCurrentIsoDate()
        if isoDate == today { return "今天" }
        if let yesterday = highlightIsoDateByAddingDays(-1, to: today), isoDate == yesterday { return "昨天" }
        guard let date = highlightParseIsoDate(isoDate) else { return isoDate }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    private func highlightParseIsoDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }

    private func highlightIsoDateByAddingDays(_ days: Int, to iso: String) -> String? {
        guard let date = highlightParseIsoDate(iso) else { return nil }
        guard let updated = calendar.date(byAdding: .day, value: days, to: date) else { return nil }
        let out = DateFormatter()
        out.locale = Locale(identifier: "en_US_POSIX")
        out.calendar = calendar
        out.dateFormat = "yyyy-MM-dd"
        return out.string(from: updated)
    }

    private func highlightCurrentIsoDate() -> String {
        let out = DateFormatter()
        out.locale = Locale(identifier: "en_US_POSIX")
        out.calendar = calendar
        out.dateFormat = "yyyy-MM-dd"
        return out.string(from: Date())
    }

    var visionPreviewItems: [VisionItemData] {
        let all = visionService.getItems(category: nil)
        if all.isEmpty { return [] }
        return Array(all.prefix(4))
    }

    func diaryCategoryLabel(_ category: DiaryCategoryData) -> String {
        diaryService.getCategoryLabel(category)
    }

    func diaryCategoryStyle(_ category: DiaryCategoryData) -> HomePageCategoryStyle {
        switch category {
        case DiaryCategoryData.work:
            return HomePageCategoryStyle(
                background: AppTheme.colors.primary.opacity(0.15),
                foreground: AppTheme.colors.onSurface
            )
        case DiaryCategoryData.health:
            return HomePageCategoryStyle(
                background: AppTheme.colors.accentGreen.opacity(0.7),
                foreground: Color(hsl: 145, 0.35, 0.35)
            )
        case DiaryCategoryData.relationship:
            return HomePageCategoryStyle(
                background: AppTheme.colors.accent.opacity(0.6),
                foreground: Color(hsl: 350, 0.4, 0.45)
            )
        case DiaryCategoryData.growth:
            return HomePageCategoryStyle(
                background: Color(hsl: 268, 0.25, 0.94),
                foreground: Color(hsl: 268, 0.4, 0.5)
            )
        case DiaryCategoryData.daily:
            return HomePageCategoryStyle(
                background: AppTheme.colors.primary.opacity(0.12),
                foreground: AppTheme.colors.onSurface
            )
        }
    }

    func shortDateText(dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        let parsed = parseDate(dateString: dateString) ?? Date()
        return formatter.string(from: parsed)
    }

    private func parseDate(dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    private func colorHslString(for type: VirtueTypeData) -> String {
        switch type {
        case VirtueTypeData.friendly: return "15 85% 75%"
        case VirtueTypeData.responsible: return "35 100% 65%"
        case VirtueTypeData.kind: return "195 75% 70%"
        case VirtueTypeData.helpful: return "120 45% 65%"
        case VirtueTypeData.grateful: return "270 60% 70%"
        case VirtueTypeData.learning: return "35 100% 65%"
        case VirtueTypeData.reliable: return "15 85% 75%"
        }
    }
}

struct HomePageCategoryStyle {
    let background: Color
    let foreground: Color
}