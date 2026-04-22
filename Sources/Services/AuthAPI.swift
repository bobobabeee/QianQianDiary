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

/// 后端登录接口请求体（username + password）
struct LoginUsernameRequest: Encodable {
    let username: String
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

/// 后端注册接口请求体
struct RegisterUsernameRequest: Encodable {
    let username: String
    let password: String
    let header: String
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

// MARK: - 响应体（登录/注册成功）

struct AuthResponse: Decodable {
    let token: String
    let phone: String?
}

/// 后端登录接口响应包装（code/data/message）
struct LoginAPIResponse: Decodable {
    let code: Int
    let data: LoginData?
    let message: String?
}

struct LoginData: Decodable {
    let token: String
    let user: UserInfo
}

/// 登录等接口里的用户对象：兼容 `id` 为数字或字符串、缺字段等情况，避免 JSON 解码失败。
struct UserInfo: Decodable {
    let header: String?
    let id: Int
    let username: String

    enum CodingKeys: String, CodingKey {
        case header, id, username
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        header = try c.decodeIfPresent(String.self, forKey: .header)
        if let v = try? c.decode(Int.self, forKey: .id) {
            id = v
        } else if let s = try? c.decode(String.self, forKey: .id), let v = Int(s) {
            id = v
        } else {
            id = 0
        }
        username = try c.decodeIfPresent(String.self, forKey: .username) ?? ""
    }
}

/// 注册接口响应包装：`data` 可能为 `null`、空 `{}` 或部分字段，只要 `code == 200` 即视为注册成功。
struct RegisterAPIResponse: Decodable {
    let code: Int
    let message: String?
    let data: RegisterResponsePayload?
}

/// 注册返回的 `data` 不做强校验（与文档完整 user 或后端只返回 `{}` 都兼容）
struct RegisterResponsePayload: Decodable {
    let id: Int?
    let username: String?
    let header: String?
}
