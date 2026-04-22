import Foundation
import Security

/// 将登录 token / 展示用手机号或用户名存入 Keychain，冷启动后仍可恢复会话（UserDefaults 仍同步一份供 APIClient 读取）。
enum KeychainCredentialStore {
    private static let service = "com.qianqiandiary.auth"
    private static let tokenAccount = "authToken"
    private static let phoneAccount = "authPhone"

    private static func save(account: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData as String] = data
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(attrs as CFDictionary, nil)
        if status != errSecSuccess {
            print("[KeychainCredentialStore] SecItemAdd 失败 account=\(account) status=\(status)")
        }
    }

    private static func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &out)
        guard status == errSecSuccess, let data = out as? Data, let s = String(data: data, encoding: .utf8), !s.isEmpty else { return nil }
        return s
    }

    static func save(token: String, phone: String) {
        save(account: tokenAccount, value: token)
        save(account: phoneAccount, value: phone)
    }

    static func readToken() -> String? { read(account: tokenAccount) }

    static func readPhone() -> String? { read(account: phoneAccount) }

    static func clear() {
        for account in [tokenAccount, phoneAccount] {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            SecItemDelete(query as CFDictionary)
        }
    }
}
