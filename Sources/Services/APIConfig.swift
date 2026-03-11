import Foundation

/// API 基础配置，接入真实后端时修改此处。
enum APIConfig {
    /// 后端 base URL，末尾不要带 /
    /// 模拟器访问本机: http://localhost:5001
    /// 真机访问本机: http://你的电脑IP:5001（需同一 WiFi）
    static var baseURL: String {
        #if DEBUG
        return ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:5001"
        #else
        return "https://your-api.example.com"
        #endif
    }

    /// 请求超时（秒）
    static let timeout: TimeInterval = 15
}
