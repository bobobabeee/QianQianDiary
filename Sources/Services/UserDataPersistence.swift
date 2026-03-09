import Foundation

/// 按用户持久化日记、美德践行记录、愿景数据到本地；未登录时不读写。
final class UserDataPersistence {

    static let shared = UserDataPersistence()

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {}

    /// 用于目录名的用户标识（手机号仅保留数字，避免非法字符）
    func sanitizedUserId(_ phone: String) -> String {
        let digits = phone.filter(\.isNumber)
        return digits.isEmpty ? "unknown" : digits
    }

    private func userDirectory(userId: String) -> URL? {
        guard let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let dir = base.appendingPathComponent("QianqianDiary", isDirectory: true)
            .appendingPathComponent("User_\(userId)", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    // MARK: - Diary

    func saveDiaryEntries(_ entries: [SuccessDiaryEntryData], userId: String) {
        guard let dir = userDirectory(userId: userId) else { return }
        let url = dir.appendingPathComponent("diary.json", isDirectory: false)
        do {
            let data = try encoder.encode(entries)
            try data.write(to: url)
        } catch {}
    }

    func loadDiaryEntries(userId: String) -> [SuccessDiaryEntryData]? {
        guard let dir = userDirectory(userId: userId) else { return nil }
        let url = dir.appendingPathComponent("diary.json", isDirectory: false)
        guard fileManager.fileExists(atPath: url.path), let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode([SuccessDiaryEntryData].self, from: data)
    }

    // MARK: - Virtue logs (definitions 为应用常量，不按用户存储)

    func saveVirtueLogs(_ logs: [VirtuePracticeLogData], userId: String) {
        guard let dir = userDirectory(userId: userId) else { return }
        let url = dir.appendingPathComponent("virtue_logs.json", isDirectory: false)
        do {
            let data = try encoder.encode(logs)
            try data.write(to: url)
        } catch {}
    }

    func loadVirtueLogs(userId: String) -> [VirtuePracticeLogData]? {
        guard let dir = userDirectory(userId: userId) else { return nil }
        let url = dir.appendingPathComponent("virtue_logs.json", isDirectory: false)
        guard fileManager.fileExists(atPath: url.path), let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode([VirtuePracticeLogData].self, from: data)
    }

    // MARK: - Vision

    func saveVisionItems(_ items: [VisionItemData], userId: String) {
        guard let dir = userDirectory(userId: userId) else { return }
        let url = dir.appendingPathComponent("vision_items.json", isDirectory: false)
        do {
            let data = try encoder.encode(items)
            try data.write(to: url)
        } catch {}
    }

    func loadVisionItems(userId: String) -> [VisionItemData]? {
        guard let dir = userDirectory(userId: userId) else { return nil }
        let url = dir.appendingPathComponent("vision_items.json", isDirectory: false)
        guard fileManager.fileExists(atPath: url.path), let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode([VisionItemData].self, from: data)
    }
}
