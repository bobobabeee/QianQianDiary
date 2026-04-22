import Foundation

/// 成功日记模块 API 请求/响应模型
/// 使用 snake_case 与后端约定一致，APIClient 自动转换

// MARK: - 响应 DTO

struct DiaryEntriesListData: Decodable {
    let total: Int
    let page: Int
    let pageSize: Int
    let items: [SuccessDiaryEntryData]
}

struct DiaryStatsAPIData: Decodable {
    let totalCount: Int
    let thisWeekCount: Int
    let topCategory: String
    let streakDays: Int
    let categoryDistribution: [DiaryCategoryDistItem]?

    private enum CodingKeys: String, CodingKey {
        case totalCount, thisWeekCount, topCategory, streakDays, categoryDistribution
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.totalCount = (try? container.decode(Int.self, forKey: .totalCount)) ?? 0
        self.thisWeekCount = (try? container.decode(Int.self, forKey: .thisWeekCount)) ?? 0
        self.topCategory = (try? container.decode(String.self, forKey: .topCategory)) ?? "DAILY"
        self.streakDays = (try? container.decode(Int.self, forKey: .streakDays)) ?? 0
        self.categoryDistribution = try? container.decode([DiaryCategoryDistItem].self, forKey: .categoryDistribution)
    }
}

struct DiaryCategoryDistItem: Decodable {
    let category: String
    let count: Int
    let label: String

    init(category: String, count: Int, label: String) {
        self.category = category
        self.count = count
        self.label = label
    }

    private enum CodingKeys: String, CodingKey {
        case category, count, label
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.category = (try? container.decode(String.self, forKey: .category)) ?? "DAILY"
        self.count = (try? container.decode(Int.self, forKey: .count)) ?? 0
        self.label = (try? container.decode(String.self, forKey: .label)) ?? ""
    }
}

struct DiaryCalendarAPIData: Decodable {
    let year: Int
    let month: Int
    let recordedDates: [String]
}

struct DiaryHighlightAPIData: Decodable {
    let id: String
    let date: String
    let displayDate: String
    let content: String
    let category: String
    let categoryLabel: String
    let categoryColor: String
    let moodIcon: String
}

// MARK: - 请求体

/// 创建日记请求体，与后端 POST /api/diary/entries 约定一致
struct DiaryCreateRequest: Encodable {
    let date: String
    let content: String
    let category: String
    let moodIcon: String

    enum CodingKeys: String, CodingKey {
        case date, content, category
        case moodIcon = "mood_icon"
    }
}

struct DiaryUpdateRequest: Encodable {
    let date: String?
    let content: String?
    let category: String?
    let moodIcon: String?
}

// MARK: - API 调用

enum DiaryAPI {
    private static let base = "/api/diary"

    static func getEntries(date: String? = nil, category: String? = nil, page: Int = 1, pageSize: Int = 20, completion: @escaping (Result<DiaryEntriesListData, Error>) -> Void) {
        var items: [URLQueryItem] = [URLQueryItem(name: "page", value: "\(page)"), URLQueryItem(name: "page_size", value: "\(pageSize)")]
        if let d = date { items.append(URLQueryItem(name: "date", value: d)) }
        if let c = category { items.append(URLQueryItem(name: "category", value: c)) }
        APIClient.shared.requestWrapped(path: "\(base)/entries", method: "GET", queryItems: items, completion: completion)
    }

    static func getEntry(id: String, completion: @escaping (Result<SuccessDiaryEntryData, Error>) -> Void) {
        APIClient.shared.requestWrapped(path: "\(base)/entries/\(id)", method: "GET", completion: completion)
    }

    static func createEntry(entry: SuccessDiaryEntryData, completion: @escaping (Result<SuccessDiaryEntryData, Error>) -> Void) {
        let req = DiaryCreateRequest(
            date: entry.date,
            content: entry.content,
            category: entry.category.rawValue,
            moodIcon: entry.moodIcon
        )
        APIClient.shared.requestWrapped(path: "\(base)/entries", method: "POST", body: req, completion: completion)
    }

    static func updateEntry(id: String, entry: SuccessDiaryEntryData, completion: @escaping (Result<SuccessDiaryEntryData, Error>) -> Void) {
        let req = DiaryUpdateRequest(date: entry.date, content: entry.content, category: entry.category.rawValue, moodIcon: entry.moodIcon)
        APIClient.shared.requestWrapped(path: "\(base)/entries/\(id)", method: "PUT", body: req, completion: completion)
    }

    static func deleteEntry(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        APIClient.shared.requestVoid(path: "\(base)/entries/\(id)", method: "DELETE", completion: completion)
    }

    static func getStats(startDate: String? = nil, endDate: String? = nil, category: String? = nil, completion: @escaping (Result<DiaryStatsAPIData, Error>) -> Void) {
        var items: [URLQueryItem] = []
        if let s = startDate { items.append(URLQueryItem(name: "start_date", value: s)) }
        if let e = endDate { items.append(URLQueryItem(name: "end_date", value: e)) }
        if let c = category { items.append(URLQueryItem(name: "category", value: c)) }
        APIClient.shared.requestWrapped(path: "\(base)/stats", method: "GET", queryItems: items.isEmpty ? nil : items, completion: completion)
    }

    static func getCalendar(year: Int, month: Int, completion: @escaping (Result<DiaryCalendarAPIData, Error>) -> Void) {
        let items = [URLQueryItem(name: "year", value: "\(year)"), URLQueryItem(name: "month", value: "\(month)")]
        APIClient.shared.requestWrapped(path: "\(base)/calendar", method: "GET", queryItems: items, completion: completion)
    }

    static func getHighlights(limit: Int = 5, completion: @escaping (Result<[DiaryHighlightAPIData], Error>) -> Void) {
        let items = [URLQueryItem(name: "limit", value: "\(limit)")]
        APIClient.shared.requestWrapped(path: "\(base)/highlights", method: "GET", queryItems: items, completion: completion)
    }
}
