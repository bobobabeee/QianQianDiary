import SwiftUI
import Foundation

@MainActor
final class DiaryCalendarViewModel: ObservableObject {
    @Published var currentMonthDate: Date
    @Published var selectedDateString: String

    private let diaryService: DiaryService
    private let calendar: Calendar

    init(initialDate: String?, diaryService: DiaryService = DiaryService.shared, calendar: Calendar = Calendar.current) {
        self.diaryService = diaryService
        self.calendar = calendar

        let resolvedSelected = initialDate?.isEmpty == false ? (initialDate ?? "") : "2026-03-04"
        self.selectedDateString = resolvedSelected

        let selectedDate = Self.parseDateString(resolvedSelected) ?? Date()
        let comps = calendar.dateComponents([.year, .month], from: selectedDate)
        self.currentMonthDate = calendar.date(from: comps) ?? selectedDate
    }

    var monthLabel: String {
        let comps = calendar.dateComponents([.year, .month], from: currentMonthDate)
        let year = comps.year ?? 0
        let monthIndex = (comps.month ?? 1) - 1
        let months = ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"]
        let safeIndex = max(0, min(11, monthIndex))
        return "\(year)年 \(months[safeIndex])"
    }

    var selectedDateDisplayText: String {
        guard let d = Self.parseDateString(selectedDateString) else { return "--" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M/d"
        return formatter.string(from: d)
    }

    var selectedEntries: [SuccessDiaryEntryData] {
        allEntries.filter { $0.date == selectedDateString }.sorted { $0.id < $1.id }
    }

    var selectedCategoryCounts: [(category: DiaryCategoryData, count: Int)] {
        var dict: [DiaryCategoryData: Int] = [:]
        for e in selectedEntries {
            dict[e.category, default: 0] += 1
        }
        let sorted = dict.sorted { pairA, pairB in
            if pairA.value != pairB.value { return pairA.value > pairB.value }
            return pairA.key.rawValue < pairB.key.rawValue
        }
        return sorted.map { ($0.key, $0.value) }
    }

    var calendarCells: [DiaryCalendarViewCalendarCell?] {
        let comps = calendar.dateComponents([.year, .month], from: currentMonthDate)
        let year = comps.year ?? 0
        let month = comps.month ?? 1

        guard let firstDay = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let dayRange = calendar.range(of: .day, in: .month, for: firstDay) else {
            return []
        }

        let startingDayOfWeek = calendar.component(.weekday, from: firstDay) - 1
        let prefixCount = max(0, startingDayOfWeek)

        var cells: [DiaryCalendarViewCalendarCell?] = Array(repeating: nil, count: prefixCount)

        let monthPrefix = String(format: "%04d-%02d", year, month)
        let countsByDate = recordCountsByDatePrefix(monthPrefix: monthPrefix)

        for day in dayRange {
            let dateStr = String(format: "%04d-%02d-%02d", year, month, day)
            let count = countsByDate[dateStr] ?? 0
            cells.append(
                DiaryCalendarViewCalendarCell(
                    day: day,
                    dateString: dateStr,
                    hasRecords: count > 0,
                    recordCount: count
                )
            )
        }

        return cells
    }

    func isSelected(dateString: String) -> Bool {
        selectedDateString == dateString
    }

    func selectDate(_ dateString: String) {
        guard !dateString.isEmpty else { return }
        selectedDateString = dateString
    }

    func goToPreviousMonth() {
        guard let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonthDate) else { return }
        let comps = calendar.dateComponents([.year, .month], from: newDate)
        currentMonthDate = calendar.date(from: comps) ?? newDate
    }

    func goToNextMonth() {
        guard let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonthDate) else { return }
        let comps = calendar.dateComponents([.year, .month], from: newDate)
        currentMonthDate = calendar.date(from: comps) ?? newDate
    }

    func categoryLabel(for category: DiaryCategoryData) -> String {
        diaryService.getCategoryLabel(category)
    }

    func deleteEntry(id: String) {
        guard !id.isEmpty else { return }
        diaryService.deleteEntry(id: id)
        objectWillChange.send()
    }

    private var allEntries: [SuccessDiaryEntryData] {
        diaryService.getEntries(date: nil, category: nil)
    }

    private func recordCountsByDatePrefix(monthPrefix: String) -> [String: Int] {
        var dict: [String: Int] = [:]
        for entry in allEntries {
            guard entry.date.hasPrefix(monthPrefix) else { continue }
            dict[entry.date, default: 0] += 1
        }
        return dict
    }

    private static func parseDateString(_ value: String) -> Date? {
        if value.isEmpty { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }
}

struct DiaryCalendarViewCalendarCell {
    let day: Int
    let dateString: String
    let hasRecords: Bool
    let recordCount: Int
}