import Foundation

enum DiaryCategoryData: String, CaseIterable, Codable {
    case work = "WORK"
    case health = "HEALTH"
    case relationship = "RELATIONSHIP"
    case growth = "GROWTH"
    case daily = "DAILY"
}

final class SuccessDiaryEntryData: Codable, Identifiable, Hashable {
    var id: String
    var date: String
    var content: String
    var category: DiaryCategoryData
    var moodIcon: String

    init(
        id: String,
        date: String,
        content: String,
        category: DiaryCategoryData,
        moodIcon: String
    ) {
        self.id = id
        self.date = date
        self.content = content
        self.category = category
        self.moodIcon = moodIcon
    }

    static func == (lhs: SuccessDiaryEntryData, rhs: SuccessDiaryEntryData) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

final class DiaryStatsSummaryData: Codable, Hashable {
    var totalCount: Int
    var thisWeekCount: Int
    var topCategory: DiaryCategoryData
    var streakDays: Int

    init(totalCount: Int, thisWeekCount: Int, topCategory: DiaryCategoryData, streakDays: Int) {
        self.totalCount = totalCount
        self.thisWeekCount = thisWeekCount
        self.topCategory = topCategory
        self.streakDays = streakDays
    }

    static func == (lhs: DiaryStatsSummaryData, rhs: DiaryStatsSummaryData) -> Bool {
        lhs.totalCount == rhs.totalCount &&
            lhs.thisWeekCount == rhs.thisWeekCount &&
            lhs.topCategory == rhs.topCategory &&
            lhs.streakDays == rhs.streakDays
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(totalCount)
        hasher.combine(thisWeekCount)
        hasher.combine(topCategory)
        hasher.combine(streakDays)
    }
}