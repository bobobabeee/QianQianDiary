import Foundation

extension Notification.Name {
    static let diaryCacheDidUpdate = Notification.Name("diaryCacheDidUpdate")
}

final class DiaryService {
    static let shared = DiaryService()

    private var categoryLabels: [DiaryCategoryData: String]
    private var entriesById: [String: SuccessDiaryEntryData]
    private var cachedUserId: String?
    private var apiEntriesCache: [SuccessDiaryEntryData] = []
    private var apiStatsCache: DiaryStatsSummaryData?
    private var apiCategoryDistribution: [DiaryCategoryDistItem] = []
    /// 后端 getCalendar 返回的有记录日期，key 为 "year-month"，用于日历小狗贴纸与本地记录同步
    private var calendarRecordedDatesCache: [String: Set<String>] = [:]

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
                apiEntriesCache = []
                apiStatsCache = nil
            }
            return
        }
        if cachedUserId == uid, !APIConfig.useRealAPI { return }
        cachedUserId = uid
        if APIConfig.useRealAPI {
            return
        }
        if let list = UserDataPersistence.shared.loadDiaryEntries(userId: uid), !list.isEmpty {
            entriesById = Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
        } else {
            entriesById = [:]
            seedSampleEntriesIfNewUser()
        }
    }

    /// 从 API 加载数据（useRealAPI 时由 ViewModel 在 onAppear 调用）
    func loadFromAPI(completion: @escaping () -> Void) {
        guard APIConfig.useRealAPI else {
            ensureLoaded()
            completion()
            return
        }
        if let uid = currentUserId() {
            cachedUserId = uid
            if apiEntriesCache.isEmpty, let saved = UserDataPersistence.shared.loadDiaryEntries(userId: uid), !saved.isEmpty {
                apiEntriesCache = saved
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .diaryCacheDidUpdate, object: nil)
                }
            }
        }
        let group = DispatchGroup()
        group.enter()
        DiaryAPI.getEntries(page: 1, pageSize: 200) { [weak self] result in
            guard let self else { group.leave(); return }
            if case .success(let data) = result {
                let currentUid = self.currentUserId()
                let locallyAdded = (currentUid == self.cachedUserId)
                    ? self.apiEntriesCache.filter { !Set(data.items.map(\.id)).contains($0.id) }
                    : [] as [SuccessDiaryEntryData]
                self.apiEntriesCache = data.items + locallyAdded
                self.cachedUserId = currentUid
                self.persistApiDiaryCacheIfNeeded()
            }
            // 失败时不清空缓存，避免网络异常或后端暂时不可用时丢失已加载/新建的记录
            group.leave()
        }
        group.enter()
        DiaryAPI.getStats { [weak self] result in
            if case .success(let data) = result {
                let cat = DiaryCategoryData(rawValue: data.topCategory) ?? .daily
                self?.apiStatsCache = DiaryStatsSummaryData(
                    totalCount: data.totalCount,
                    thisWeekCount: data.thisWeekCount,
                    topCategory: cat,
                    streakDays: data.streakDays
                )
                self?.apiCategoryDistribution = data.categoryDistribution ?? []
            } else {
                self?.apiStatsCache = nil
                self?.apiCategoryDistribution = []
            }
            group.leave()
        }
        group.notify(queue: .main) { [weak self] in
            self?.persistApiDiaryCacheIfNeeded()
            completion()
        }
    }

    /// 真实 API 模式下把当前列表快照写入 Application Support，冷启动可先展示再与服务器合并
    private func persistApiDiaryCacheIfNeeded() {
        guard APIConfig.useRealAPI else { return }
        guard let uid = currentUserId() ?? cachedUserId else { return }
        UserDataPersistence.shared.saveDiaryEntries(apiEntriesCache, userId: uid)
    }

    /// 拉取某月有记录的日期，与本地缓存合并，供日历显示小狗贴纸
    func loadCalendarForMonth(year: Int, month: Int, completion: @escaping () -> Void) {
        guard APIConfig.useRealAPI else {
            completion()
            return
        }
        let key = String(format: "%d-%d", year, month)
        DiaryAPI.getCalendar(year: year, month: month) { [weak self] result in
            if case .success(let data) = result {
                self?.calendarRecordedDatesCache[key] = Set(data.recordedDates)
            }
            DispatchQueue.main.async { completion() }
        }
    }

    /// 某月有记录的日期集合（API + 本地新建的日期）
    func recordedDatesForMonth(year: Int, month: Int) -> Set<String> {
        let key = String(format: "%d-%d", year, month)
        let monthPrefix = String(format: "%04d-%02d", year, month)
        let fromApi = calendarRecordedDatesCache[key] ?? []
        let fromLocal = Set(apiEntriesCache
            .filter { $0.date.hasPrefix(monthPrefix) }
            .map(\.date))
        return fromApi.union(fromLocal)
    }

    /// 登出或切换账号时清空所有缓存，确保不泄露上一账号数据
    func clearAllCaches() {
        cachedUserId = nil
        entriesById = [:]
        apiEntriesCache = []
        apiStatsCache = nil
        apiCategoryDistribution = []
        calendarRecordedDatesCache = [:]
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .diaryCacheDidUpdate, object: nil)
        }
    }

    /// 按日期查询当日日记，直接返回接口结果，不缓存（供日历点击某日时调用）
    func fetchEntriesForDate(_ date: String, completion: @escaping ([SuccessDiaryEntryData]) -> Void) {
        guard !date.isEmpty else {
            DispatchQueue.main.async { completion([]) }
            return
        }
        if !APIConfig.useRealAPI {
            ensureLoaded()
            let list = entriesById.values.filter { $0.date == date }.sorted { $0.id < $1.id }
            DispatchQueue.main.async { completion(list) }
            return
        }
        print("[DiaryService] fetchEntriesForDate(\(date)) 开始请求…")
        DiaryAPI.getEntries(date: date, page: 1, pageSize: 50) { [weak self] result in
            switch result {
            case .success(let data):
                print("[DiaryService] fetchEntriesForDate(\(date)) 成功, 共 \(data.items.count) 条记录 (total=\(data.total))")
                DispatchQueue.main.async { completion(data.items) }
            case .failure(let error):
                print("[DiaryService] fetchEntriesForDate(\(date)) 失败: \(error)")
                let fallback = self?.apiEntriesCache.filter { $0.date == date } ?? []
                print("[DiaryService] 回退到缓存, 找到 \(fallback.count) 条")
                DispatchQueue.main.async { completion(fallback) }
            }
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
        if APIConfig.useRealAPI {
            if let found = apiEntriesCache.first(where: { $0.id == id }) { return found }
            return defaultEntry(id: id, date: currentDateString(), category: .daily)
        }
        ensureLoaded()
        if let found = entriesById[id] { return found }
        return defaultEntry(id: id, date: currentDateString(), category: .daily)
    }

    func getEntriesByDate(_ date: String) -> [SuccessDiaryEntryData] {
        let list: [SuccessDiaryEntryData]
        if APIConfig.useRealAPI {
            list = apiEntriesCache.filter { $0.date == date }.sorted { $0.id < $1.id }
        } else {
            ensureLoaded()
            list = entriesById.values.filter { $0.date == date }.sorted { $0.id < $1.id }
        }
        if !list.isEmpty { return list }
        return [defaultEntry(id: "d-fallback-\(date)", date: date, category: .daily)]
    }

    func getEntries(date: String? = nil, category: DiaryCategoryData? = nil) -> [SuccessDiaryEntryData] {
        let all: [SuccessDiaryEntryData]
        if APIConfig.useRealAPI {
            all = apiEntriesCache
        } else {
            ensureLoaded()
            all = Array(entriesById.values)
        }
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

    func upsertEntry(_ entry: SuccessDiaryEntryData, completion: ((Result<Void, Error>) -> Void)? = nil) {
        if APIConfig.useRealAPI {
            // 必须在 normalize 之前判断：normalizeEntry 会给空 id 生成客户端 UUID，
            // 若用 normalized.id.isEmpty 判断会永远走「更新」，导致对新日记发 PUT 而服务器无此 id。
            let isNew = entry.id.isEmpty
            let normalized = normalizeEntry(entry)
            if isNew {
                let forCreate = SuccessDiaryEntryData(
                    id: "",
                    date: normalized.date,
                    content: normalized.content,
                    category: normalized.category,
                    moodIcon: normalized.moodIcon
                )
                DiaryAPI.createEntry(entry: forCreate) { [weak self] result in
                    if case .success(let created) = result {
                        self?.apiEntriesCache.append(created)
                        self?.persistApiDiaryCacheIfNeeded()
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .diaryCacheDidUpdate, object: nil)
                        }
                    }
                    completion?(result.map { _ in () })
                }
            } else {
                DiaryAPI.updateEntry(id: normalized.id, entry: normalized) { [weak self] result in
                    if case .success(let updated) = result {
                        if let idx = self?.apiEntriesCache.firstIndex(where: { $0.id == updated.id }) {
                            self?.apiEntriesCache[idx] = updated
                        } else {
                            self?.apiEntriesCache.append(updated)
                        }
                        self?.persistApiDiaryCacheIfNeeded()
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .diaryCacheDidUpdate, object: nil)
                        }
                    }
                    completion?(result.map { _ in () })
                }
            }
            return
        }
        ensureLoaded()
        let normalized = normalizeEntry(entry)
        entriesById[normalized.id] = normalized
        saveToPersistence()
        completion?(.success(()))
    }

    func deleteEntry(id: String, completion: ((Result<Void, Error>) -> Void)? = nil) {
        if APIConfig.useRealAPI {
            DiaryAPI.deleteEntry(id: id) { [weak self] result in
                if case .success = result {
                    self?.apiEntriesCache.removeAll { $0.id == id }
                    self?.persistApiDiaryCacheIfNeeded()
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .diaryCacheDidUpdate, object: nil)
                    }
                }
                completion?(result)
            }
            return
        }
        ensureLoaded()
        entriesById.removeValue(forKey: id)
        saveToPersistence()
        completion?(.success(()))
    }

    func getStatsSummary() -> DiaryStatsSummaryData {
        if APIConfig.useRealAPI {
            if let stats = apiStatsCache { return stats }
            return computeStatsSummary(entries: apiEntriesCache, category: nil)
        }
        ensureLoaded()
        let entries = Array(entriesById.values)
        return computeStatsSummary(entries: entries, category: nil)
    }

    func getCategoryDistribution() -> [DiaryCategoryDistItem] {
        if APIConfig.useRealAPI, !apiCategoryDistribution.isEmpty {
            return apiCategoryDistribution
        }
        if APIConfig.useRealAPI {
            return buildCategoryDistributionFromEntries(apiEntriesCache)
        }
        return apiCategoryDistribution
    }

    private func buildCategoryDistributionFromEntries(_ entries: [SuccessDiaryEntryData]) -> [DiaryCategoryDistItem] {
        var counts: [DiaryCategoryData: Int] = [:]
        for e in entries { counts[e.category, default: 0] += 1 }
        return DiaryCategoryData.allCases.compactMap { cat in
            guard let c = counts[cat], c > 0 else { return nil }
            return DiaryCategoryDistItem(category: cat.rawValue, count: c, label: getCategoryLabel(cat))
        }
    }

    /// 按日期范围请求统计数据（包含 categoryDistribution），完成后更新缓存
    func fetchStats(startDate: String? = nil, endDate: String? = nil, category: String? = nil, completion: @escaping () -> Void) {
        guard APIConfig.useRealAPI else { completion(); return }
        DiaryAPI.getStats(startDate: startDate, endDate: endDate, category: category) { [weak self] result in
            if case .success(let data) = result {
                let cat = DiaryCategoryData(rawValue: data.topCategory) ?? .daily
                self?.apiStatsCache = DiaryStatsSummaryData(
                    totalCount: data.totalCount,
                    thisWeekCount: data.thisWeekCount,
                    topCategory: cat,
                    streakDays: data.streakDays
                )
                self?.apiCategoryDistribution = data.categoryDistribution ?? []
                print("[DiaryService] ✅ 统计数据加载成功: total=\(data.totalCount) categories=\(data.categoryDistribution?.count ?? 0)")
            } else if case .failure(let error) = result {
                print("[DiaryService] ❌ 统计数据加载失败: \(error)")
            }
            DispatchQueue.main.async { completion() }
        }
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
