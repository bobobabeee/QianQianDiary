import Foundation

final class DiaryService {
    static let shared = DiaryService()

    private var categoryLabels: [DiaryCategoryData: String]
    private var entriesById: [String: SuccessDiaryEntryData]
    private var cachedUserId: String?

    private init() {
        self.categoryLabels = [
            .work: "职业成就",
            .health: "身体健康",
            .relationship: "人际关系",
            .growth: "个人成长",
            .daily: "日常微光"
        ]
        self.entriesById = [:]
    }

    private func currentUserId() -> String? {
        let phone = AuthService.shared.currentPhone
        guard !phone.isEmpty else { return nil }
        return UserDataPersistence.shared.sanitizedUserId(phone)
    }

    private func ensureLoaded() {
        guard let uid = currentUserId() else {
            if cachedUserId != nil {
                entriesById = [:]
                cachedUserId = nil
            }
            return
        }
        if cachedUserId == uid { return }
        cachedUserId = uid
        if let list = UserDataPersistence.shared.loadDiaryEntries(userId: uid), !list.isEmpty {
            entriesById = Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
        } else {
            entriesById = [:]
            seedSampleEntriesIfNewUser()
        }
    }

    /// 新用户首次进入时写入一两条示例成功日记，并立即持久化
    private func seedSampleEntriesIfNewUser() {
        let today = currentDateString()
        let samples: [SuccessDiaryEntryData] = [
            SuccessDiaryEntryData(
                id: "d-sample-1",
                date: today,
                content: "早起给自己做了一顿丰盛的早餐。",
                category: .daily,
                moodIcon: "Sun"
            ),
            SuccessDiaryEntryData(
                id: "d-sample-2",
                date: today,
                content: "读完了一章《小狗钱钱》，做了笔记。",
                category: .growth,
                moodIcon: "BookOpen"
            )
        ]
        for e in samples { entriesById[e.id] = e }
        saveToPersistence()
    }

    private func saveToPersistence() {
        guard let uid = cachedUserId else { return }
        let list = Array(entriesById.values)
        UserDataPersistence.shared.saveDiaryEntries(list, userId: uid)
    }

    func getCategoryLabel(_ category: DiaryCategoryData) -> String {
        categoryLabels[category] ?? "未分类"
    }

    func getAllCategoryLabels() -> [DiaryCategoryData: String] {
        var result: [DiaryCategoryData: String] = [:]
        for c in DiaryCategoryData.allCases {
            result[c] = getCategoryLabel(c)
        }
        return result
    }

    func getEntry(id: String) -> SuccessDiaryEntryData {
        ensureLoaded()
        if let found = entriesById[id] { return found }
        return defaultEntry(id: id, date: currentDateString(), category: .daily)
    }

    func getEntriesByDate(_ date: String) -> [SuccessDiaryEntryData] {
        ensureLoaded()
        let list = entriesById.values.filter { $0.date == date }.sorted { $0.id < $1.id }
        if !list.isEmpty { return list }
        return [defaultEntry(id: "d-fallback-\(date)", date: date, category: .daily)]
    }

    func getEntries(date: String? = nil, category: DiaryCategoryData? = nil) -> [SuccessDiaryEntryData] {
        ensureLoaded()
        let all = Array(entriesById.values)
        let filtered = all.filter { entry in
            if let date, entry.date != date { return false }
            if let category, entry.category != category { return false }
            return true
        }.sorted { $0.date == $1.date ? $0.id < $1.id : $0.date > $1.date }

        if !filtered.isEmpty { return filtered }

        let fallbackDate = date ?? currentDateString()
        let fallbackCategory = category ?? .daily
        return [defaultEntry(id: "d-fallback-\(fallbackDate)-\(fallbackCategory.rawValue)", date: fallbackDate, category: fallbackCategory)]
    }

    func upsertEntry(_ entry: SuccessDiaryEntryData) {
        ensureLoaded()
        let normalized = normalizeEntry(entry)
        entriesById[normalized.id] = normalized
        saveToPersistence()
    }

    func deleteEntry(id: String) {
        ensureLoaded()
        entriesById.removeValue(forKey: id)
        saveToPersistence()
    }

    func getStatsSummary() -> DiaryStatsSummaryData {
        ensureLoaded()
        let entries = Array(entriesById.values)
        return computeStatsSummary(entries: entries, category: nil)
    }

    func getStatsSummary(dateRange: ClosedRange<String>?, category: DiaryCategoryData?) -> DiaryStatsSummaryData {
        let entries = getEntries(date: nil, category: nil)

        let ranged: [SuccessDiaryEntryData] = entries.filter { e in
            if let category, e.category != category { return false }
            if let dateRange {
                return e.date >= dateRange.lowerBound && e.date <= dateRange.upperBound
            }
            return true
        }

        return computeStatsSummary(entries: ranged, category: category)
    }

    private func computeStatsSummary(entries: [SuccessDiaryEntryData], category: DiaryCategoryData?) -> DiaryStatsSummaryData {
        if entries.isEmpty {
            return DiaryStatsSummaryData(totalCount: 0, thisWeekCount: 0, topCategory: category ?? .daily, streakDays: 0)
        }
        var counts: [DiaryCategoryData: Int] = [:]
        for e in entries {
            counts[e.category, default: 0] += 1
        }
        let top = counts.max(by: { $0.value < $1.value })?.key ?? (category ?? .daily)
        let calendar = Calendar.current
        let today = currentDateString()
        let weekCount = entries.filter { e in
            guard e.date <= today else { return false }
            guard let d = isoDateToDate(e.date) else { return false }
            return calendar.isDate(d, equalTo: Date(), toGranularity: .weekOfYear)
        }.count
        var streakDays = 0
        var check = isoDateToDate(today)
        let sortedDates = Set(entries.map(\.date)).sorted(by: >)
        while check != nil, sortedDates.contains(dateToString(check!)) {
            streakDays += 1
            check = calendar.date(byAdding: .day, value: -1, to: check!)
        }
        return DiaryStatsSummaryData(
            totalCount: entries.count,
            thisWeekCount: weekCount,
            topCategory: top,
            streakDays: streakDays
        )
    }

    private func isoDateToDate(_ s: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: s)
    }

    private func dateToString(_ d: Date) -> String {
        currentDateString(date: d)
    }

    private func defaultEntry(id: String, date: String, category: DiaryCategoryData) -> SuccessDiaryEntryData {
        SuccessDiaryEntryData(
            id: id,
            date: date,
            content: "今天也有值得记录的一小步。",
            category: category,
            moodIcon: "Sun"
        )
    }

    private func normalizeEntry(_ entry: SuccessDiaryEntryData) -> SuccessDiaryEntryData {
        let normalizedId = entry.id.isEmpty ? "d-\(UUID().uuidString)" : entry.id
        let normalizedDate = entry.date.isEmpty ? currentDateString() : entry.date
        let normalizedContent = entry.content.isEmpty ? "今天也有值得记录的一小步。" : entry.content
        let normalizedIcon = entry.moodIcon.isEmpty ? "Sun" : entry.moodIcon
        return SuccessDiaryEntryData(
            id: normalizedId,
            date: normalizedDate,
            content: normalizedContent,
            category: entry.category,
            moodIcon: normalizedIcon
        )
    }

    private func currentDateString(date: Date = Date(), calendar: Calendar = .current) -> String {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}