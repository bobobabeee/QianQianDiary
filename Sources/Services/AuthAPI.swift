import Foundation

/// 认证相关 API 的请求/响应模型，与后端约定一致后用于 APIClient。
/// 字段名使用 snake_case，与 APIClient 的 keyDecodingStrategy 对应。

// MARK: - 请求体

struct SendSMSRequest: Encodable {
    let phone: String
}

struct LoginPasswordRequest: Encodable {
    let phone: String
    let password: String
}

struct LoginSMSRequest: Encodable {
    let phone: String
    let code: String
}

struct RegisterRequest: Encodable {
    let phone: String
    let code: String
    let password: String
}

struct ResetPasswordRequest: Encodable {
    let phone: String
    let code: String
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case phone, code
        case newPassword = "new_password"
    }
}

// MARK: - 与后端统一格式对应的请求体（字段 sms_code）

struct RegisterRequestAPI: Encodable {
    let phone: String
    let smsCode: String
    let password: String
    enum CodingKeys: String, CodingKey {
        case phone, password
        case smsCode = "sms_code"
    }
}

struct LoginSMSRequestAPI: Encodable {
    let phone: String
    let smsCode: String
    enum CodingKeys: String, CodingKey {
        case phone
        case smsCode = "sms_code"
    }
}

struct ResetPasswordRequestAPI: Encodable {
    let phone: String
    let smsCode: String
    let newPassword: String
    enum CodingKeys: String, CodingKey {
        case phone
        case smsCode = "sms_code"
        case newPassword = "new_password"
    }
}

// MARK: - 响应体（登录/注册成功，data 内）

struct AuthData: Decodable {
    let token: String
    let refreshToken: String?
    let userId: Int?
    let phone: String?
    enum CodingKeys: String, CodingKey {
        case token
        case refreshToken = "refresh_token"
        case userId = "user_id"
        case phone
    }
}

struct AuthResponse: Decodable {
    let token: String
    let phone: String?
}
