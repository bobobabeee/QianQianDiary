import Foundation

/// 用户信息模块 API

struct UserProfileAPIData: Decodable {
    let id: Int
    let username: String
    let header: String?
}

struct UserProfileUpdateRequest: Encodable {
    let username: String?
    let header: String?
}

struct ChangePasswordRequest: Encodable {
    let oldPassword: String
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case oldPassword = "old_password"
        case newPassword = "new_password"
    }
}

enum UserAPI {
    private static let base = "/api/user"

    static func getProfile(completion: @escaping (Result<UserProfileAPIData, Error>) -> Void) {
        APIClient.shared.requestWrapped(path: "\(base)/profile", method: "GET", completion: completion)
    }

    static func updateProfile(username: String? = nil, header: String? = nil, completion: @escaping (Result<UserProfileAPIData, Error>) -> Void) {
        let req = UserProfileUpdateRequest(username: username, header: header)
        APIClient.shared.requestWrapped(path: "\(base)/profile", method: "PUT", body: req, completion: completion)
    }

    static func changePassword(oldPassword: String, newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let req = ChangePasswordRequest(oldPassword: oldPassword, newPassword: newPassword)
        APIClient.shared.requestVoid(path: "\(base)/change-password", method: "POST", body: req, completion: completion)
    }
}
