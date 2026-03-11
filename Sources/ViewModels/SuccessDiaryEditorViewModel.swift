import SwiftUI
import Foundation

@MainActor
final class SuccessDiaryEditorViewModel: ObservableObject {
    enum SuccessDiaryEditorCategory: String, CaseIterable {
        case work = "WORK"
        case health = "HEALTH"
        case relationship = "RELATIONSHIP"
        case growth = "GROWTH"
        case daily = "DAILY"
    }

    @Published var content: String = ""
    @Published var selectedCategory: SuccessDiaryEditorCategory = SuccessDiaryEditorCategory.daily
    @Published var selectedDate: String = ""
    @Published var isSubmitting: Bool = false
    @Published var validationError: String = ""

    private let diaryService: DiaryService

    init(diaryService: DiaryService = DiaryService.shared) {
        self.diaryService = diaryService
        self.selectedDate = Self.currentDateString()
    }

    var contentCountText: String {
        "\(content.count) / 500 字符"
    }

    var categoryDisplayText: String {
        diaryService.getCategoryLabel(categoryData(from: selectedCategory))
    }

    var dateDisplayText: String {
        Self.formatDateDisplay(selectedDate)
    }

    /// 将日期字符串格式化为展示文案（今天 / 昨天 / M月d日），供选择列表等使用
    static func displayText(for dateStr: String) -> String {
        formatDateDisplay(dateStr)
    }

    var dateRange: [String] {
        Self.makeDateRange(daysBack: 30)
    }

    func onAppearResetForm() {
        content = ""
        selectedCategory = SuccessDiaryEditorCategory.daily
        selectedDate = Self.currentDateString()
        validationError = ""
    }

    func validateForm() -> Bool {
        validationError = ""

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            validationError = "请输入成功事件描述"
            return false
        }

        if trimmed.count < 5 {
            validationError = "描述至少需要5个字符"
            return false
        }

        return true
    }

    func save(router: AppRouter) {
        guard !isSubmitting else { return }
        guard validateForm() else { return }

        isSubmitting = true

        Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: 500_000_000)

                let entry = SuccessDiaryEntryData(
                    id: "",
                    date: self.selectedDate,
                    content: self.content.trimmingCharacters(in: .whitespacesAndNewlines),
                    category: self.categoryData(from: self.selectedCategory),
                    moodIcon: self.categoryIconName(self.selectedCategory)
                )
                self.diaryService.upsertEntry(entry)

                self.isSubmitting = false
                router.navigate(to: AppRouter.Destination.diaryCalendarView(date: self.selectedDate), style: AppRouter.NavigationStyle.push)
            } catch {
                self.isSubmitting = false
                self.validationError = "保存失败，请重试"
            }
        }
    }

    func categoryIconName(_ category: SuccessDiaryEditorCategory) -> String {
        switch category {
        case SuccessDiaryEditorCategory.work:
            return "Briefcase"
        case SuccessDiaryEditorCategory.health:
            return "Heart"
        case SuccessDiaryEditorCategory.relationship:
            return "Users"
        case SuccessDiaryEditorCategory.growth:
            return "Zap"
        case SuccessDiaryEditorCategory.daily:
            return "Sun"
        }
    }

    func categoryLabel(_ category: SuccessDiaryEditorCategory) -> String {
        diaryService.getCategoryLabel(categoryData(from: category))
    }

    private func categoryData(from category: SuccessDiaryEditorCategory) -> DiaryCategoryData {
        switch category {
        case SuccessDiaryEditorCategory.work: return DiaryCategoryData.work
        case SuccessDiaryEditorCategory.health: return DiaryCategoryData.health
        case SuccessDiaryEditorCategory.relationship: return DiaryCategoryData.relationship
        case SuccessDiaryEditorCategory.growth: return DiaryCategoryData.growth
        case SuccessDiaryEditorCategory.daily: return DiaryCategoryData.daily
        }
    }

    private static func makeDateRange(daysBack: Int) -> [String] {
        let calendar = Calendar.current
        let today = Date()
        let safeDaysBack = max(0, daysBack)

        guard let startDate = calendar.date(byAdding: .day, value: -safeDaysBack, to: today) else {
            return [currentDateString(date: today)]
        }

        var dates: [String] = []
        var d = startDate

        while d <= today {
            dates.append(currentDateString(date: d, calendar: calendar))
            guard let next = calendar.date(byAdding: .day, value: 1, to: d) else { break }
            d = next
        }

        return dates.sorted(by: <)
    }

    private static func formatDateDisplay(_ dateStr: String) -> String {
        let todayStr = currentDateString()
        if dateStr == todayStr { return "今天" }

        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
            let yStr = currentDateString(date: yesterday)
            if dateStr == yStr { return "昨天" }
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"

        guard let date = formatter.date(from: dateStr) else {
            return dateStr
        }

        let out = DateFormatter()
        out.locale = Locale(identifier: "zh_CN")
        out.dateFormat = "M月d日"
        return out.string(from: date)
    }

    private static func currentDateString(date: Date = Date(), calendar: Calendar = .current) -> String {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}