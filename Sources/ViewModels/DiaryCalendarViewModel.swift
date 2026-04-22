import SwiftUI
import Foundation

@MainActor
final class DiaryCalendarViewModel: ObservableObject {
    @Published var currentMonthDate: Date
    @Published var selectedDateString: String
    /// 当日历点击某日期时，直接展示接口返回结果，不做缓存
    @Published var entriesForSelectedDate: [SuccessDiaryEntryData] = []

    private let diaryService: DiaryService
    private let calendar: Calendar

    init(initialDate: String?, diaryService: DiaryService = DiaryService.shared, calendar: Calendar = Calendar.current) {
        self.diaryService = diaryService
        self.calendar = calendar

        let resolvedSelected = initialDate?.isEmpty == false ? (initialDate ?? "") : Self.currentDateString()
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
        entriesForSelectedDate.sorted { $0.id < $1.id }
    }

    /// 选中的日期是否为未来（超过今天），未来日期不允许补记
    var isSelectedDateInFuture: Bool {
        selectedDateString > Self.currentDateString()
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
        let apiRecordedDates = diaryService.recordedDatesForMonth(year: year, month: month)

        for day in dayRange {
            let dateStr = String(format: "%04d-%02d-%02d", year, month, day)
            let count = countsByDate[dateStr] ?? 0
            let hasRecords = count > 0 || apiRecordedDates.contains(dateStr)
            cells.append(
                DiaryCalendarViewCalendarCell(
                    day: day,
                    dateString: dateStr,
                    hasRecords: hasRecords,
                    recordCount: hasRecords ? max(count, 1) : 0
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
        entriesForSelectedDate = []
        Task {
            let items = await fetchEntries(for: dateString)
            self.entriesForSelectedDate = items
        }
    }

    func goToPreviousMonth() {
        guard let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonthDate) else { return }
        let comps = calendar.dateComponents([.year, .month], from: newDate)
        currentMonthDate = calendar.date(from: comps) ?? newDate
        let year = comps.year ?? 0
        let month = comps.month ?? 1
        diaryService.loadCalendarForMonth(year: year, month: month) { [weak self] in
            Task { @MainActor in
                self?.objectWillChange.send()
            }
        }
    }

    func goToNextMonth() {
        guard let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonthDate) else { return }
        let comps = calendar.dateComponents([.year, .month], from: newDate)
        currentMonthDate = calendar.date(from: comps) ?? newDate
        let year = comps.year ?? 0
        let month = comps.month ?? 1
        diaryService.loadCalendarForMonth(year: year, month: month) { [weak self] in
            Task { @MainActor in
                self?.objectWillChange.send()
            }
        }
    }

    func categoryLabel(for category: DiaryCategoryData) -> String {
        diaryService.getCategoryLabel(category)
    }

    func loadFromAPI(completion: @escaping () -> Void) {
        let comps = calendar.dateComponents([.year, .month], from: currentMonthDate)
        let year = comps.year ?? 0
        let month = comps.month ?? 1
        let group = DispatchGroup()
        group.enter()
        diaryService.loadFromAPI { group.leave() }
        group.enter()
        diaryService.loadCalendarForMonth(year: year, month: month) { group.leave() }
        group.notify(queue: .main) { [weak self] in
            guard let self else { completion(); return }
            Task {
                let items = await self.fetchEntries(for: self.selectedDateString)
                self.entriesForSelectedDate = items
                completion()
            }
        }
    }

    /// 补记后或缓存更新时重新拉取当日记录
    func refreshEntriesForSelectedDate() {
        Task {
            let items = await fetchEntries(for: selectedDateString)
            self.entriesForSelectedDate = items
        }
    }

    func deleteEntry(id: String) {
        guard !id.isEmpty else { return }
        diaryService.deleteEntry(id: id) { [weak self] _ in
            Task { @MainActor in
                self?.refreshEntriesForSelectedDate()
            }
        }
    }

    /// 将 callback 版 fetchEntriesForDate 转为 async，保证在 @MainActor 上安全调用
    private func fetchEntries(for date: String) async -> [SuccessDiaryEntryData] {
        await withCheckedContinuation { continuation in
            diaryService.fetchEntriesForDate(date) { items in
                continuation.resume(returning: items)
            }
        }
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

    private static func currentDateString(date: Date = Date(), calendar: Calendar = .current) -> String {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}

struct DiaryCalendarViewCalendarCell {
    let day: Int
    let dateString: String
    let hasRecords: Bool
    let recordCount: Int
}