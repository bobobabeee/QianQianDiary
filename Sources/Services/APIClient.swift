import Foundation

/// 统一 HTTP 客户端：带 Base URL、Bearer Token，JSON 编解码。
/// 接入真实 API 时，在 AuthService 等处用此 client 发起请求。
final class APIClient {

    static let shared = APIClient()

    private let session: URLSession
    private let uploadSession: URLSession
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

        let uploadConfig = URLSessionConfiguration.default
        uploadConfig.timeoutIntervalForRequest = 120
        uploadConfig.timeoutIntervalForResource = 300
        self.uploadSession = URLSession(configuration: uploadConfig)
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

    /// POST，`Content-Type` / `Accept` 为 JSON，`Authorization: Bearer <token>`（写入 URLRequest 标准头字段），请求体为 UTF-8 的 `{}`。
    /// 用于仅需鉴权、后端接受空 JSON 对象的接口（如注销账号）。
    func requestPostEmptyJSONObject(path: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: APIConfig.baseURL + path) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = authToken, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = Data("{}".utf8)

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

    /// 统一响应包装 { code, message, data }，code==200 时返回 data，否则失败
    func requestWrapped<T: Decodable>(
        path: String,
        method: String = "GET",
        queryItems: [URLQueryItem]? = nil,
        body: (any Encodable)? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
//        var pathWithQuery = path
        if let items = queryItems, !items.isEmpty {
            var components = URLComponents(string: APIConfig.baseURL + path)
            components?.queryItems = items
            guard let url = components?.url else {
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
                do { request.httpBody = try encoder.encode(AnyEncodable(body)) } catch {
                    completion(.failure(error)); return
                }
            }
            performWrappedRequest(request: request, completion: completion)
            return
        }

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
            do { request.httpBody = try encoder.encode(AnyEncodable(body)) } catch {
                completion(.failure(error)); return
            }
        }
        performWrappedRequest(request: request, completion: completion)
    }

    private func performWrappedRequest<T: Decodable>(
        request: URLRequest,
        using customSession: URLSession? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        let activeSession = customSession ?? session
        activeSession.dataTask(with: request) { [weak self] data, response, error in
            let urlStr = request.url?.absoluteString ?? "unknown"
            if let error = error {
                print("[APIClient] ❌ \(request.httpMethod ?? "?") \(urlStr) 网络错误: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            let http = response as? HTTPURLResponse
            let status = http?.statusCode ?? 0
            let rawData = data ?? Data()
            let rawJSON = String(data: rawData, encoding: .utf8) ?? "(empty)"
            print("[APIClient] \(request.httpMethod ?? "?") \(urlStr) → HTTP \(status)")
            print("[APIClient] 响应体: \(rawJSON.prefix(500))")

            if status >= 200, status < 300 {
                do {
                    let wrapper = try self?.decoder.decode(APIResponseWrapper<T>.self, from: rawData)
                    guard let w = wrapper, w.code == 200, let d = w.data else {
                        let msg = wrapper?.message ?? "请求失败"
                        print("[APIClient] ⚠️ 业务码非200或data为空: code=\(wrapper?.code ?? -1) msg=\(wrapper?.message ?? "nil")")
                        DispatchQueue.main.async { completion(.failure(APIError.serverMessage(msg, statusCode: status))) }
                        return
                    }
                    print("[APIClient] ✅ 解码成功: \(T.self)")
                    DispatchQueue.main.async { completion(.success(d)) }
                } catch {
                    print("[APIClient] ❌ JSON解码失败(\(T.self)): \(error)")
                    DispatchQueue.main.async { completion(.failure(error)) }
                }
                return
            }
            print("[APIClient] ❌ HTTP错误 \(status)")
            let apiError = self?.parseError(data: rawData, statusCode: status) ?? APIError.httpStatus(status)
            DispatchQueue.main.async { completion(.failure(apiError)) }
        }.resume()
    }

    /// Multipart form-data 上传文件，响应按 { code, message, data } 解码
    func uploadFile<T: Decodable>(
        path: String,
        fileData: Data,
        fileName: String,
        mimeType: String = "image/jpeg",
        fieldName: String = "file",
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: APIConfig.baseURL + path) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = authToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let sizeMB = String(format: "%.2f", Double(fileData.count) / 1_048_576.0)
        print("[APIClient] 上传文件 \(fileName) (\(sizeMB) MB) → \(url.absoluteString)")
        performWrappedRequest(request: request, using: uploadSession, completion: completion)
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

/// 统一响应包装 { code, message, data } 的解码结构
private struct APIResponseWrapper<T: Decodable>: Decodable {
    let code: Int
    let message: String?
    let data: T?
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
