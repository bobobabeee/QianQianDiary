import CryptoKit
import Foundation
import UIKit

/// 按 URL 缓存远程图片：内存（NSCache）+ 磁盘（Caches），减少重复下载。
/// 用于 RemoteImage / 愿景板等；登出时 `clearAll()` 避免账号间残留。
final class ImageURLCache {
    static let shared = ImageURLCache()

    private let memory = NSCache<NSString, UIImage>()
    private let lock = NSLock()
    private var inflight: [String: Task<UIImage?, Never>] = [:]

    private var diskDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImageURLCache", isDirectory: true)
    }

    private init() {
        memory.countLimit = 120
        memory.totalCostLimit = 80 * 1024 * 1024
        try? FileManager.default.createDirectory(at: diskDirectory, withIntermediateDirectories: true)
    }

    /// 稳定文件名（避免 URL 中特殊字符）
    static func storageKey(for urlString: String) -> String {
        let digest = SHA256.hash(data: Data(urlString.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func diskURL(forKey key: String) -> URL {
        diskDirectory.appendingPathComponent(key + ".bin", isDirectory: false)
    }

    /// 在主线程同步读内存 + 磁盘（不发起网络）。用于 SwiftUI 首帧直接显示已缓存图，避免先闪「加载中」。
    func synchronousCachedUIImage(for urlString: String) -> UIImage? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let scheme = URL(string: trimmed)?.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return nil
        }
        let key = Self.storageKey(for: trimmed)
        lock.lock()
        if let m = memory.object(forKey: key as NSString) {
            lock.unlock()
            return m
        }
        lock.unlock()
        let fileURL = diskURL(forKey: key)
        guard let data = try? Data(contentsOf: fileURL), let img = UIImage(data: data) else { return nil }
        memory.setObject(img, forKey: key as NSString, cost: data.count)
        return img
    }

    func uiImage(for urlString: String) async -> UIImage? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return nil
        }

        let key = Self.storageKey(for: trimmed)

        lock.lock()
        if let existing = inflight[key] {
            lock.unlock()
            return await existing.value
        }
        let task = Task { [self] in
            await self.loadOrDownload(url: url, key: key)
        }
        inflight[key] = task
        lock.unlock()

        let image = await task.value

        lock.lock()
        inflight[key] = nil
        lock.unlock()
        return image
    }

    private func loadOrDownload(url: URL, key: String) async -> UIImage? {
        let fileURL = diskURL(forKey: key)
        if let data = try? Data(contentsOf: fileURL), let img = UIImage(data: data) {
            memory.setObject(img, forKey: key as NSString, cost: data.count)
            return img
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 120
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }
            guard let img = UIImage(data: data) else { return nil }
            memory.setObject(img, forKey: key as NSString, cost: data.count)
            try? data.write(to: fileURL, options: [.atomic])
            return img
        } catch {
            return nil
        }
    }

    func clearMemory() {
        memory.removeAllObjects()
    }

    func clearAll() {
        memory.removeAllObjects()
        lock.lock()
        inflight.values.forEach { $0.cancel() }
        inflight.removeAll()
        lock.unlock()
        try? FileManager.default.removeItem(at: diskDirectory)
        try? FileManager.default.createDirectory(at: diskDirectory, withIntermediateDirectories: true)
    }

    /// 上传成功后把已压缩的 JPEG 写入缓存，列表页首次展示同一 URL 时无需再拉网。
    func storeDownloadedData(_ data: Data, for urlString: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let scheme = URL(string: trimmed)?.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return }
        guard let img = UIImage(data: data) else { return }
        let key = Self.storageKey(for: trimmed)
        memory.setObject(img, forKey: key as NSString, cost: data.count)
        try? data.write(to: diskURL(forKey: key), options: .atomic)
    }
}
