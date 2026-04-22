import SwiftUI
import Foundation

@MainActor final class VirtueGrowthStatsViewModel: ObservableObject {
    enum VirtueGrowthStatsTab: String {
        case virtue
        case success
    }

    struct VirtueGrowthStatsVirtueStat {
        let count: Int
        let lastDate: String?
    }

    struct VirtueGrowthStatsSortedVirtueRow {
        let type: VirtueTypeData
        let name: String
        let iconName: String
        let count: Int
    }

    struct VirtueGrowthStatsDistributionSlice {
        let type: VirtueTypeData
        let name: String
        let count: Int
        let percentageText: String
        let startAngle: Double
        let endAngle: Double
        let color: Color
    }

    struct VirtueGrowthStatsTimelineGroup {
        let date: String
        let displayDate: String
        let logs: [VirtuePracticeLogData]
    }

    @Published var selectedTab: VirtueGrowthStatsTab = VirtueGrowthStatsTab.virtue
    @Published var isContentReady: Bool = false

    @Published private var definitions: [VirtueTypeData: VirtueDefinitionData] = [:]
    @Published private var logs: [VirtuePracticeLogData] = []

    private let virtueService: VirtueService
    private let calendar: Calendar

    init(
        virtueService: VirtueService = VirtueService.shared,
        calendar: Calendar = Calendar.current
    ) {
        self.virtueService = virtueService
        self.calendar = calendar
        load()
    }

    func onAppear() {
        reloadFromAPI()
        if isContentReady { return }
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 120_000_000)
            await MainActor.run {
                self?.isContentReady = true
            }
        }
    }

    func reloadFromAPI() {
        virtueService.loadFromAPI { [weak self] in
            guard let self else { return }
            let defs = self.virtueService.getAllVirtueDefinitions()
            self.definitions = Dictionary(uniqueKeysWithValues: defs.map { ($0.type, $0) })
            self.logs = self.virtueService.getVirtuePracticeLogs(date: nil, virtueType: nil)
        }
    }

    var virtueStats: [VirtueTypeData: VirtueGrowthStatsVirtueStat] {
        var stats: [VirtueTypeData: VirtueGrowthStatsVirtueStat] = [:]
        for t in VirtueTypeData.allCases {
            stats[t] = VirtueGrowthStatsVirtueStat(count: 0, lastDate: nil)
        }

        for log in logs {
            if !log.isCompleted { continue }
            let segments = max(1, Self.reflectionSegmentCount(log.reflection))
            let current = stats[log.virtueType] ?? VirtueGrowthStatsVirtueStat(count: 0, lastDate: nil)
            let nextCount = current.count + segments
            let nextLastDate: String?
            if let existingLast = current.lastDate {
                nextLastDate = max(existingLast, log.date)
            } else {
                nextLastDate = log.date
            }
            stats[log.virtueType] = VirtueGrowthStatsVirtueStat(count: nextCount, lastDate: nextLastDate)
        }

        return stats
    }

    var totalPracticesText: String {
        "\(totalPractices)"
    }

    var virtuesCoveredText: String {
        "\(virtuesCovered)/7"
    }

    var consecutiveDaysText: String {
        "\(consecutiveDays)天"
    }

    var sortedVirtues: [VirtueGrowthStatsSortedVirtueRow] {
        let rows: [VirtueGrowthStatsSortedVirtueRow] = VirtueTypeData.allCases.map { type in
            let def = definitions[type] ?? virtueService.getVirtueDefinition(type: type)
            let stat = virtueStats[type]?.count ?? 0
            return VirtueGrowthStatsSortedVirtueRow(
                type: type,
                name: def.name,
                iconName: def.iconName,
                count: stat
            )
        }
        return rows.sorted { a, b in
            if a.count == b.count { return a.name < b.name }
            return a.count > b.count
        }
    }

    var maxCount: Int {
        let counts = sortedVirtues.map { $0.count }
        return max(counts.max() ?? 0, 1)
    }

    var distributionSlices: [VirtueGrowthStatsDistributionSlice] {
        let total = totalPractices
        if total <= 0 { return [] }

        let palette: [Color] = [
            AppTheme.colors.chart1,
            AppTheme.colors.chart2,
            AppTheme.colors.chart3,
            AppTheme.colors.chart4,
            AppTheme.colors.chart5,
            AppTheme.colors.primary,
            AppTheme.colors.secondary
        ]

        let included = VirtueTypeData.allCases.compactMap { type -> (VirtueTypeData, VirtueDefinitionData, Int)? in
            let count = virtueStats[type]?.count ?? 0
            if count <= 0 { return nil }
            let def = definitions[type] ?? virtueService.getVirtueDefinition(type: type)
            return (type, def, count)
        }

        var currentAngle: Double = 0
        var result: [VirtueGrowthStatsDistributionSlice] = []
        for (index, item) in included.enumerated() {
            let percentage = (Double(item.2) / Double(max(total, 1))) * 100.0
            let sliceAngle = (Double(item.2) / Double(max(total, 1))) * 360.0
            let start = currentAngle
            let end = currentAngle + sliceAngle
            currentAngle = end

            let percentText = String(format: "%.1f%%", percentage)
            let color = palette.indices.contains(index) ? palette[index] : palette[index % max(palette.count, 1)]

            result.append(
                VirtueGrowthStatsDistributionSlice(
                    type: item.0,
                    name: item.1.name,
                    count: item.2,
                    percentageText: percentText,
                    startAngle: start,
                    endAngle: end,
                    color: color
                )
            )
        }
        return result
    }

    var timelineGroups: [VirtueGrowthStatsTimelineGroup] {
        let completed = logs
            .filter { $0.isCompleted }
            .sorted { $0.date > $1.date }

        if completed.isEmpty { return [] }

        let expanded = Self.expandLogsForTimeline(completed)
        var byDate: [String: [VirtuePracticeLogData]] = [:]
        for log in expanded {
            byDate[log.date, default: []].append(log)
        }

        let sortedDates = byDate.keys.sorted(by: >)
        return sortedDates.map { date in
            let groupLogs = (byDate[date] ?? []).sorted { lhs, rhs in
                if lhs.virtueType.rawValue != rhs.virtueType.rawValue {
                    return lhs.virtueType.rawValue < rhs.virtueType.rawValue
                }
                return lhs.id < rhs.id
            }
            return VirtueGrowthStatsTimelineGroup(
                date: date,
                displayDate: displayDateLabel(for: date),
                logs: groupLogs
            )
        }
    }

    func virtueName(for type: VirtueTypeData) -> String {
        let def = definitions[type] ?? virtueService.getVirtueDefinition(type: type)
        return def.name
    }

    func virtueIconName(for type: VirtueTypeData) -> String {
        let def = definitions[type] ?? virtueService.getVirtueDefinition(type: type)
        return def.iconName
    }

    /// 今日日期 yyyy-MM-dd
    var todayDateString: String {
        isoDateString(from: calendar.startOfDay(for: Date()))
    }

    /// 今日美德定义
    var todayVirtueDefinition: VirtueDefinitionData {
        virtueService.getTodayVirtueDefinition(date: Date(), calendar: calendar)
    }

    /// 今日践行记录（含是否完成与心得）
    var todayPracticeLog: VirtuePracticeLogData {
        let today = todayDateString
        let def = todayVirtueDefinition
        let dayLogs = virtueService.getVirtuePracticeLogs(date: today, virtueType: nil)
        if let match = dayLogs.first(where: { $0.virtueType == def.type }) { return match }
        if let first = dayLogs.first { return first }
        return VirtuePracticeLogData(
            id: "local-empty-\(today)-\(def.type.rawValue)",
            date: today,
            virtueType: def.type,
            isCompleted: false,
            reflection: ""
        )
    }

    private var totalPractices: Int {
        VirtueTypeData.allCases.reduce(0) { partial, type in
            partial + (virtueStats[type]?.count ?? 0)
        }
    }

    private var virtuesCovered: Int {
        VirtueTypeData.allCases.reduce(0) { partial, type in
            partial + ((virtueStats[type]?.count ?? 0) > 0 ? 1 : 0)
        }
    }

    private var consecutiveDays: Int {
        let completedDates = Set(logs.filter { $0.isCompleted }.map { $0.date })
        if completedDates.isEmpty { return 0 }

        var count = 0
        var date = calendar.startOfDay(for: Date())

        while true {
            let key = isoDateString(from: date)
            if completedDates.contains(key) {
                count += 1
                if let prev = calendar.date(byAdding: .day, value: -1, to: date) {
                    date = prev
                    continue
                }
            }
            break
        }
        return count
    }

    private func load() {
        reloadFromAPI()
    }

    private static func reflectionSegmentCount(_ reflection: String) -> Int {
        let parts = reflection.components(separatedBy: VirtueService.virtueReflectionEntrySeparator)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return max(1, parts.count)
    }

    /// 将合并保存的多段心得拆成多条时间轴条目（同日同类型仍是一条 API 记录）
    private static func expandLogsForTimeline(_ logs: [VirtuePracticeLogData]) -> [VirtuePracticeLogData] {
        let sep = VirtueService.virtueReflectionEntrySeparator
        var out: [VirtuePracticeLogData] = []
        for log in logs {
            let parts = log.reflection.components(separatedBy: sep)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if parts.count <= 1 {
                out.append(log)
                continue
            }
            for (i, part) in parts.enumerated() {
                out.append(
                    VirtuePracticeLogData(
                        id: "\(log.id)#\(i)",
                        date: log.date,
                        virtueType: log.virtueType,
                        isCompleted: log.isCompleted,
                        reflection: part
                    )
                )
            }
        }
        return out
    }

    private func displayDateLabel(for isoDate: String) -> String {
        let todayKey = isoDateString(from: calendar.startOfDay(for: Date()))
        if isoDate == todayKey { return "今天" }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date())) {
            let yesterdayKey = isoDateString(from: calendar.startOfDay(for: yesterday))
            if isoDate == yesterdayKey { return "昨天" }
        }

        if let date = parseIsoDate(isoDate) {
            return chineseMonthDay(from: date)
        }

        return isoDate
    }

    private func parseIsoDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = calendar
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }

    private func isoDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = calendar
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func chineseMonthDay(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: date)
    }
}