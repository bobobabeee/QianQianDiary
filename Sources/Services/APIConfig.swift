import Foundation

/// 用户可选的 API 部署区域（对应不同 Base URL）
enum APIServerRegion: String, CaseIterable, Identifiable {
    case singapore = "singapore"
    case mainlandChina = "mainland_china"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .singapore: return "新加坡"
        case .mainlandChina: return "中国大陆"
        }
    }
}

/// API 基础配置。根据「设置 → 服务器线路」或首次启动时的系统地区选择 Base URL。
enum APIConfig {
    private static let regionUserDefaultsKey = "api.server.region"

    // MARK: - 把下面两个地址改成你两台服务器真实的 Base URL（末尾不要带 /）

    /// 新加坡节点
    private static let singaporeBaseURL = "https://bobobabeee.zeabur.app"
    /// 中国大陆节点
    private static let mainlandChinaBaseURL = "https://poppydiary.top"

    /// 首次安装且未手动选过线路时：系统地区为中国则用大陆节点，否则用新加坡节点。
    static func applyDefaultRegionIfNeeded() {
        guard UserDefaults.standard.object(forKey: regionUserDefaultsKey) == nil else { return }
        let def: APIServerRegion = (Locale.current.region?.identifier == "CN") ? .mainlandChina : .singapore
        UserDefaults.standard.set(def.rawValue, forKey: regionUserDefaultsKey)
    }

    /// 当前选择的线路（持久化在 UserDefaults）
    static var selectedServerRegion: APIServerRegion {
        get {
            guard let raw = UserDefaults.standard.string(forKey: regionUserDefaultsKey),
                  let r = APIServerRegion(rawValue: raw) else {
                return .singapore
            }
            return r
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: regionUserDefaultsKey)
        }
    }

    /// 切换线路并持久化（不处理登录态；界面层应在切换后视情况退出登录）
    static func setServerRegion(_ region: APIServerRegion) {
        selectedServerRegion = region
    }

    /// 当前线路对应的 Base URL（末尾不要带 /）
    static var baseURL: String {
        switch selectedServerRegion {
        case .singapore: return singaporeBaseURL
        case .mainlandChina: return mainlandChinaBaseURL
        }
    }

    /// 请求超时（秒）
    static let timeout: TimeInterval = 15

    /// 是否使用真实后端 API（日记、美德、愿景、用户等模块）
    static let useRealAPI: Bool = true
}
