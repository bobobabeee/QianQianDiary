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
        if isContentReady { return }
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 120_000_000)
            await MainActor.run {
                self?.isContentReady = true
            }
        }
    }

    var virtueStats: [VirtueTypeData: VirtueGrowthStatsVirtueStat] {
        var stats: [VirtueTypeData: VirtueGrowthStatsVirtueStat] = [:]
        for t in VirtueTypeData.allCases {
            stats[t] = VirtueGrowthStatsVirtueStat(count: 0, lastDate: nil)
        }

        for log in logs {
            if !log.isCompleted { continue }
            let current = stats[log.virtueType] ?? VirtueGrowthStatsVirtueStat(count: 0, lastDate: nil)
            let nextCount = current.count + 1
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

        var byDate: [String: [VirtuePracticeLogData]] = [:]
        for log in completed {
            byDate[log.date, default: []].append(log)
        }

        let sortedDates = byDate.keys.sorted(by: >)
        return sortedDates.map { date in
            let groupLogs = byDate[date] ?? []
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
        return dayLogs.first { $0.virtueType == def.type } ?? dayLogs.first!
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
        let defs = virtueService.getAllVirtueDefinitions()
        definitions = Dictionary(uniqueKeysWithValues: defs.map { ($0.type, $0) })
        logs = virtueService.getVirtuePracticeLogs(date: nil, virtueType: nil)
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