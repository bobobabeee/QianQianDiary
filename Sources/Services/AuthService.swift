import Foundation

/// 登录状态与接口。设为 true 时走真实 API（需配置 APIConfig.baseURL 并实现后端）。
private let useRealAuthAPI = true

/// 登录状态与接口；useRealAuthAPI 为 false 时为模拟实现。
final class AuthService: ObservableObject {
    static let shared = AuthService()

    private let tokenKey = "authToken"
    private let phoneKey = "authPhone"  // 真实 API 时存储 username

    @Published private(set) var isLoggedIn: Bool = false
    @Published private(set) var currentPhone: String = ""  // 真实 API 时存 username，用于展示

    private init() {
        var token = KeychainCredentialStore.readToken()
        var phone = KeychainCredentialStore.readPhone() ?? ""

        if token == nil || token?.isEmpty == true {
            let udToken = UserDefaults.standard.string(forKey: tokenKey)
            let udPhone = UserDefaults.standard.string(forKey: phoneKey) ?? ""
            if let t = udToken, !t.isEmpty {
                KeychainCredentialStore.save(token: t, phone: udPhone)
                token = t
                phone = udPhone
            }
        }

        currentPhone = phone
        if let t = token, !t.isEmpty {
            UserDefaults.standard.set(t, forKey: tokenKey)
            UserDefaults.standard.set(phone, forKey: phoneKey)
            APIClient.shared.authToken = t
            isLoggedIn = true
        } else {
            isLoggedIn = false
        }
    }

    /// 用户名 + 密码登录（对接真实后端 /api/auth/login）
    func login(username: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { completion(.failure(AuthError.invalidUsername)); return }
        guard !password.isEmpty else { completion(.failure(AuthError.invalidPassword)); return }

        if useRealAuthAPI {
            APIClient.shared.request(path: "/api/auth/login", method: "POST", body: LoginUsernameRequest(username: trimmed, password: password)) { [weak self] (result: Result<LoginAPIResponse, Error>) in
                switch result {
                case .success(let res):
                    guard res.code == 200, let data = res.data else {
                        completion(.failure(AuthError.serverError(res.message ?? "登录失败")))
                        return
                    }
                    self?.saveSession(phone: data.user.username, token: data.token)
                    APIClient.shared.authToken = data.token
                    completion(.success(()))
                case .failure(let e):
                    completion(.failure(e))
                }
            }
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.saveSession(phone: trimmed, token: "token-\(trimmed)-\(Date().timeIntervalSince1970)")
            completion(.success(()))
        }
    }

    /// 手机号 + 密码登录（兼容旧逻辑，模拟时使用）
    func login(phone: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        if useRealAuthAPI {
            login(username: phone, password: password, completion: completion)
            return
        }
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 11 else { completion(.failure(AuthError.invalidPhone)); return }
        guard !password.isEmpty else { completion(.failure(AuthError.invalidPassword)); return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.saveSession(phone: trimmed, token: "token-\(trimmed)-\(Date().timeIntervalSince1970)")
            completion(.success(()))
        }
    }

    /// 手机号 + 验证码登录
    func login(phone: String, code: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 11 else { completion(.failure(AuthError.invalidPhone)); return }
        let codeTrimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard codeTrimmed.count >= 4, codeTrimmed.allSatisfy(\.isNumber) else { completion(.failure(AuthError.invalidCode)); return }

        if useRealAuthAPI {
            APIClient.shared.request(path: "/auth/login/sms", method: "POST", body: LoginSMSRequest(phone: trimmed, code: codeTrimmed)) { [weak self] (result: Result<AuthResponse, Error>) in
                switch result {
                case .success(let res):
                    self?.saveSession(phone: res.phone ?? trimmed, token: res.token)
                    APIClient.shared.authToken = res.token
                    completion(.success(()))
                case .failure(let e):
                    completion(.failure(e))
                }
            }
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.saveSession(phone: trimmed, token: "sms-\(trimmed)-\(Date().timeIntervalSince1970)")
            completion(.success(()))
        }
    }

    /// 发送验证码
    func sendSMSCode(phone: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 11 else { completion(.failure(AuthError.invalidPhone)); return }

        if useRealAuthAPI {
            APIClient.shared.requestVoid(path: "/auth/sms/send", method: "POST", body: SendSMSRequest(phone: trimmed), completion: completion)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { completion(.success(())) }
    }

    /// 用户名 + 密码注册（对接真实后端 /api/auth/regist）
    /// 注册成功后自动调用登录接口获取 token 并完成登录
    func register(username: String, password: String, header: String = "", completion: @escaping (Result<Void, Error>) -> Void) {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { completion(.failure(AuthError.invalidUsername)); return }
        guard password.count >= 6 else { completion(.failure(AuthError.passwordTooShort)); return }

        if useRealAuthAPI {
            APIClient.shared.request(path: "/api/auth/regist", method: "POST", body: RegisterUsernameRequest(username: trimmed, password: password, header: header)) { [weak self] (result: Result<RegisterAPIResponse, Error>) in
                switch result {
                case .success(let res):
                    guard res.code == 200 else {
                        completion(.failure(AuthError.serverError(res.message ?? "注册失败")))
                        return
                    }
                    // 注册成功，后端不返回 token，需调用登录接口完成登录
                    self?.login(username: trimmed, password: password, completion: completion)
                case .failure(let e):
                    completion(.failure(e))
                }
            }
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.saveSession(phone: trimmed, token: "reg-\(trimmed)-\(Date().timeIntervalSince1970)")
            completion(.success(()))
        }
    }

    /// 手机号 + 验证码 + 密码注册（兼容旧逻辑，模拟时使用）
    func register(phone: String, code: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        if useRealAuthAPI {
            register(username: phone, password: password, completion: completion)
            return
        }
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 11 else { completion(.failure(AuthError.invalidPhone)); return }
        let codeTrimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard codeTrimmed.count >= 4, codeTrimmed.allSatisfy(\.isNumber) else { completion(.failure(AuthError.invalidCode)); return }
        guard password.count >= 6 else { completion(.failure(AuthError.passwordTooShort)); return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.saveSession(phone: trimmed, token: "reg-\(trimmed)-\(Date().timeIntervalSince1970)")
            completion(.success(()))
        }
    }

    /// 重置密码
    func resetPassword(phone: String, code: String, newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 11 else { completion(.failure(AuthError.invalidPhone)); return }
        let codeTrimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard codeTrimmed.count >= 4, codeTrimmed.allSatisfy(\.isNumber) else { completion(.failure(AuthError.invalidCode)); return }
        guard newPassword.count >= 6 else { completion(.failure(AuthError.passwordTooShort)); return }

        if useRealAuthAPI {
            APIClient.shared.requestVoid(path: "/auth/password/reset", method: "POST", body: ResetPasswordRequest(phone: trimmed, code: codeTrimmed, newPassword: newPassword), completion: completion)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { completion(.success(())) }
    }

    /// 服务端注销账号：POST /api/auth/delete，Header `Authorization: Bearer`，Body `{}`。成功后须由调用方执行 `logout()` 与路由回登录页。
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        if useRealAuthAPI {
            APIClient.shared.requestPostEmptyJSONObject(path: "/api/auth/delete", completion: completion)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { completion(.success(())) }
    }

    func logout() {
        clearAllUserDataCaches()
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: phoneKey)
        KeychainCredentialStore.clear()
        APIClient.shared.authToken = nil
        DispatchQueue.main.async { [weak self] in
            self?.isLoggedIn = false
            self?.currentPhone = ""
        }
    }

    /// 登出或登录前清空各业务模块缓存，确保账号数据隔离
    private func clearAllUserDataCaches() {
        DiaryService.shared.clearAllCaches()
        VirtueService.shared.clearAllCaches()
        VisionService.shared.clearAllCaches()
        ImageURLCache.shared.clearAll()
    }

    private func saveSession(phone: String, token: String) {
        clearAllUserDataCaches()
        UserDefaults.standard.set(token, forKey: tokenKey)
        UserDefaults.standard.set(phone, forKey: phoneKey)
        KeychainCredentialStore.save(token: token, phone: phone)
        APIClient.shared.authToken = token
        isLoggedIn = true
        currentPhone = phone
    }
}

enum AuthError: LocalizedError {
    case invalidPhone
    case invalidUsername
    case invalidPassword
    case invalidCode
    case network
    case passwordTooShort
    case passwordMismatch
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidPhone: return "请输入正确的手机号"
        case .invalidUsername: return "请输入用户名"
        case .invalidPassword: return "请输入密码"
        case .invalidCode: return "请输入正确的验证码"
        case .network: return "网络异常，请重试"
        case .passwordTooShort: return "密码至少 6 位"
        case .passwordMismatch: return "两次输入的密码不一致"
        case .serverError(let msg): return msg
        }
    }
}
