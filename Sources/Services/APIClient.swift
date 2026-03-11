import Foundation

/// 统一 HTTP 客户端：带 Base URL、Bearer Token，JSON 编解码。
/// 接入真实 API 时，在 AuthService 等处用此 client 发起请求。
final class APIClient {

    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    /// 当前登录态 token，请求头会带 Authorization: Bearer <token>
    var authToken: String? {
        get { UserDefaults.standard.string(forKey: "authToken") }
        set { UserDefaults.standard.set(newValue, forKey: "authToken") }
    }

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.timeout
        config.timeoutIntervalForResource = APIConfig.timeout
        self.session = URLSession(configuration: config)
    }

    /// 发起请求并解析 JSON 为 T；失败时通过 completion 返回 APIError 或解码错误。
    func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: APIConfig.baseURL + path) else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = authToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            do {
                request.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                completion(.failure(error))
                return
            }
        }

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            let http = response as? HTTPURLResponse
            let status = http?.statusCode ?? 0
            let data = data ?? Data()

            if status >= 200, status < 300 {
                do {
                    let decoded = try self?.decoder.decode(T.self, from: data)
                    DispatchQueue.main.async { completion(.success(decoded!)) }
                } catch {
                    DispatchQueue.main.async { completion(.failure(error)) }
                }
                return
            }

            let apiError = self?.parseError(data: data, statusCode: status) ?? APIError.httpStatus(status)
            DispatchQueue.main.async { completion(.failure(apiError)) }
        }
        task.resume()
    }

    /// 统一返回格式 { code, msg, data }：成功时解析 data 为 T
    func requestUnified<T: Decodable>(
        path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: APIConfig.baseURL + path) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = authToken, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            do { req.httpBody = try encoder.encode(AnyEncodable(body)) } catch {
                completion(.failure(error))
                return
            }
        }
        session.dataTask(with: req) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let raw = data ?? Data()
            struct UnifiedBody<D: Decodable>: Decodable {
                let code: Int?
                let msg: String?
                let data: D?
            }
            guard let wrapper = try? self?.decoder.decode(UnifiedBody<T>.self, from: raw) else {
                if code >= 200, code < 300 {
                    DispatchQueue.main.async { completion(.failure(APIError.serverMessage("响应格式错误", statusCode: code))) }
                } else {
                    let apiError = self?.parseUnifiedError(data: raw, statusCode: code) ?? APIError.httpStatus(code)
                    DispatchQueue.main.async { completion(.failure(apiError)) }
                }
                return
            }
            let backendCode = wrapper.code ?? 200
            if backendCode == 200, let payload = wrapper.data {
                DispatchQueue.main.async { completion(.success(payload)) }
                return
            }
            let msg = wrapper.msg ?? "请求失败"
            DispatchQueue.main.async { completion(.failure(APIError.serverMessage(msg, statusCode: backendCode))) }
        }.resume()
    }

    /// 统一返回格式 { code, msg }：2xx 且 code==200 即成功，无需解析 data
    func requestVoidUnified(
        path: String,
        method: String = "POST",
        body: (any Encodable)? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: APIConfig.baseURL + path) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = authToken, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            do { req.httpBody = try encoder.encode(AnyEncodable(body)) } catch {
                completion(.failure(error))
                return
            }
        }
        struct VoidUnifiedBody: Decodable {
            let code: Int?
            let msg: String?
        }
        session.dataTask(with: req) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let raw = data ?? Data()
            guard let wrapper = try? self?.decoder.decode(VoidUnifiedBody.self, from: raw) else {
                let apiError = self?.parseUnifiedError(data: raw, statusCode: code) ?? APIError.httpStatus(code)
                DispatchQueue.main.async { completion(.failure(apiError)) }
                return
            }
            let backendCode = wrapper.code ?? 200
            if backendCode == 200 {
                DispatchQueue.main.async { completion(.success(())) }
                return
            }
            let msg = wrapper.msg ?? "请求失败"
            DispatchQueue.main.async { completion(.failure(APIError.serverMessage(msg, statusCode: backendCode))) }
        }.resume()
    }

    private struct UnifiedWrapper<T: Decodable>: Decodable {
        let code: Int?
        let msg: String?
        let data: T?
    }

    private func parseUnifiedError(data: Data, statusCode: Int) -> APIError {
        struct UnifiedErrorBody: Decodable {
            let code: Int?
            let msg: String?
        }
        if let body = try? decoder.decode(UnifiedErrorBody.self, from: data), let msg = body.msg, !msg.isEmpty {
            return .serverMessage(msg, statusCode: body.code ?? statusCode)
        }
        return .httpStatus(statusCode)
    }

    /// 无响应体的请求（如登录、注册、发送验证码），2xx 即视为成功
    func requestVoid(
        path: String,
        method: String = "POST",
        body: (any Encodable)? = nil,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: APIConfig.baseURL + path) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = authToken, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            do { req.httpBody = try encoder.encode(AnyEncodable(body)) } catch {
                completion(.failure(error))
                return
            }
        }
        session.dataTask(with: req) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            if code >= 200, code < 300 {
                DispatchQueue.main.async { completion(.success(())) }
                return
            }
            let apiError = self?.parseError(data: data ?? Data(), statusCode: code) ?? APIError.httpStatus(code)
            DispatchQueue.main.async { completion(.failure(apiError)) }
        }.resume()
    }

    private func parseError(data: Data, statusCode: Int) -> APIError {
        struct ErrorBody: Decodable { let message: String?; let error: String? }
        guard let body = try? decoder.decode(ErrorBody.self, from: data) else {
            return .httpStatus(statusCode)
        }
        let msg = body.message ?? body.error ?? "请求失败"
        return .serverMessage(msg, statusCode: statusCode)
    }
}

/// 任意 Encodable 类型擦除，便于 request(body: Encodable)
private struct AnyEncodable: Encodable {
    let value: any Encodable
    init(_ value: any Encodable) { self.value = value }
    func encode(to encoder: Encoder) throws { try value.encode(to: encoder) }
}

enum APIError: LocalizedError {
    case invalidURL
    case httpStatus(Int)
    case serverMessage(String, statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "请求地址无效"
        case .httpStatus(let code):
            if code == 401 { return "登录已过期，请重新登录" }
            if code >= 500 { return "服务器繁忙，请稍后重试" }
            return "请求失败(\(code))"
        case .serverMessage(let msg, _): return msg
        }
    }
}
