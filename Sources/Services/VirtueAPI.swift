import Foundation

/// 美德践行模块 API 请求/响应模型

// MARK: - 响应 DTO

struct VirtueTodayAPIData: Decodable {
    let definition: VirtueDefinitionData
    let practiceLog: VirtuePracticeLogAPIData
}

struct VirtuePracticeLogAPIData: Decodable {
    let id: String?
    let date: String
    let virtueType: String
    let isCompleted: Bool
    let reflection: String

    private enum CodingKeys: String, CodingKey {
        case id, date, virtueType, isCompleted, reflection
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let intId = try? container.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else {
            self.id = try? container.decode(String.self, forKey: .id)
        }
        self.date = (try? container.decode(String.self, forKey: .date)) ?? ""
        self.virtueType = (try? container.decode(String.self, forKey: .virtueType)) ?? "FRIENDLY"
        if let boolVal = try? container.decode(Bool.self, forKey: .isCompleted) {
            self.isCompleted = boolVal
        } else if let intVal = try? container.decode(Int.self, forKey: .isCompleted) {
            self.isCompleted = intVal != 0
        } else {
            self.isCompleted = false
        }
        self.reflection = (try? container.decode(String.self, forKey: .reflection)) ?? ""
    }
}

struct VirtueLogsListData: Decodable {
    let total: Int
    let page: Int
    let pageSize: Int
    let items: [VirtuePracticeLogData]
}

struct VirtueStatsAPIData: Decodable {
    let totalPractices: Int
    let virtuesCovered: Int
    let streakDays: Int
    let typeDistribution: [VirtueTypeDistItem]?
}

struct VirtueTypeDistItem: Decodable {
    let virtueType: String
    let count: Int
    let name: String
}

// MARK: - 请求体

struct VirtueLogUpsertRequest: Encodable {
    let date: String
    let virtueType: String
    let isCompleted: Bool
    let reflection: String
}

// MARK: - API 调用

enum VirtueAPI {
    private static let base = "/api/virtue"

    static func getDefinitions(completion: @escaping (Result<[VirtueDefinitionData], Error>) -> Void) {
        APIClient.shared.requestWrapped(path: "\(base)/definitions", method: "GET", completion: completion)
    }

    static func getToday(date: String? = nil, completion: @escaping (Result<VirtueTodayAPIData, Error>) -> Void) {
        var items: [URLQueryItem] = []
        if let d = date { items.append(URLQueryItem(name: "date", value: d)) }
        APIClient.shared.requestWrapped(path: "\(base)/today", method: "GET", queryItems: items.isEmpty ? nil : items, completion: completion)
    }

    static func getLogs(date: String? = nil, virtueType: String? = nil, page: Int = 1, pageSize: Int = 20, completion: @escaping (Result<VirtueLogsListData, Error>) -> Void) {
        var items: [URLQueryItem] = [URLQueryItem(name: "page", value: "\(page)"), URLQueryItem(name: "page_size", value: "\(pageSize)")]
        if let d = date { items.append(URLQueryItem(name: "date", value: d)) }
        if let v = virtueType { items.append(URLQueryItem(name: "virtue_type", value: v)) }
        APIClient.shared.requestWrapped(path: "\(base)/logs", method: "GET", queryItems: items, completion: completion)
    }

    static func upsertLog(log: VirtuePracticeLogData, completion: @escaping (Result<VirtuePracticeLogData, Error>) -> Void) {
        let req = VirtueLogUpsertRequest(
            date: log.date,
            virtueType: log.virtueType.rawValue,
            isCompleted: log.isCompleted,
            reflection: log.reflection
        )
        APIClient.shared.requestWrapped(path: "\(base)/logs", method: "POST", body: req, completion: completion)
    }

    static func getStats(completion: @escaping (Result<VirtueStatsAPIData, Error>) -> Void) {
        APIClient.shared.requestWrapped(path: "\(base)/stats", method: "GET", completion: completion)
    }
}
