import Foundation

/// API 基础配置，接入真实后端时修改此处。
enum APIConfig {
    /// 后端 base URL，末尾不要带 /
    /// 开发: "https://your-api.example.com" 或 "http://localhost:8080"
    static var baseURL: String {
        #if DEBUG
        return ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "https://your-api.example.com"
        #else
        return "https://your-api.example.com"
        #endif
    }

    /// 请求超时（秒）
    static let timeout: TimeInterval = 15
}
