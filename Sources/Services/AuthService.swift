import Foundation

/// 登录状态与接口。设为 true 时走真实 API（需配置 APIConfig.baseURL 并实现后端）。
private let useRealAuthAPI = false

/// 登录状态与接口；useRealAuthAPI 为 false 时为模拟实现。
final class AuthService: ObservableObject {
    static let shared = AuthService()

    private let tokenKey = "authToken"
    private let phoneKey = "authPhone"

    @Published private(set) var isLoggedIn: Bool = false
    @Published private(set) var currentPhone: String = ""

    private init() {
        let token = UserDefaults.standard.string(forKey: tokenKey)
        currentPhone = UserDefaults.standard.string(forKey: phoneKey) ?? ""
        isLoggedIn = (token != nil && !(token?.isEmpty ?? true))
        if isLoggedIn, let t = token { APIClient.shared.authToken = t }
    }

    /// 手机号 + 密码登录
    func login(phone: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 11 else { completion(.failure(AuthError.invalidPhone)); return }
        guard !password.isEmpty else { completion(.failure(AuthError.invalidPassword)); return }

        if useRealAuthAPI {
            APIClient.shared.request(path: "/auth/login", method: "POST", body: LoginPasswordRequest(phone: trimmed, password: password)) { [weak self] (result: Result<AuthResponse, Error>) in
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

    /// 注册
    func register(phone: String, code: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 11 else { completion(.failure(AuthError.invalidPhone)); return }
        let codeTrimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard codeTrimmed.count >= 4, codeTrimmed.allSatisfy(\.isNumber) else { completion(.failure(AuthError.invalidCode)); return }
        guard password.count >= 6 else { completion(.failure(AuthError.passwordTooShort)); return }

        if useRealAuthAPI {
            APIClient.shared.request(path: "/auth/register", method: "POST", body: RegisterRequest(phone: trimmed, code: codeTrimmed, password: password)) { [weak self] (result: Result<AuthResponse, Error>) in
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

    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: phoneKey)
        APIClient.shared.authToken = nil
        DispatchQueue.main.async { [weak self] in
            self?.isLoggedIn = false
            self?.currentPhone = ""
        }
    }

    private func saveSession(phone: String, token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        UserDefaults.standard.set(phone, forKey: phoneKey)
        APIClient.shared.authToken = token
        isLoggedIn = true
        currentPhone = phone
    }
}

enum AuthError: LocalizedError {
    case invalidPhone
    case invalidPassword
    case invalidCode
    case network
    case passwordTooShort
    case passwordMismatch

    var errorDescription: String? {
        switch self {
        case .invalidPhone: return "请输入正确的手机号"
        case .invalidPassword: return "请输入密码"
        case .invalidCode: return "请输入正确的验证码"
        case .network: return "网络异常，请重试"
        case .passwordTooShort: return "密码至少 6 位"
        case .passwordMismatch: return "两次输入的密码不一致"
        }
    }
}
