import Foundation

// MARK: - 图片上传

struct UploadImageResponseData: Decodable {
    let url: String
}

enum UploadAPI {
    static func uploadImage(data: Data, fileName: String = "image.jpg", completion: @escaping (Result<String, Error>) -> Void) {
        APIClient.shared.uploadFile(
            path: "/api/upload/image",
            fileData: data,
            fileName: fileName,
            mimeType: "image/jpeg"
        ) { (result: Result<UploadImageResponseData, Error>) in
            switch result {
            case .success(let resp):
                print("[UploadAPI] ✅ 图片上传成功: \(resp.url)")
                completion(.success(resp.url))
            case .failure(let error):
                print("[UploadAPI] ❌ 图片上传失败: \(error)")
                completion(.failure(error))
            }
        }
    }
}

/// 愿景板模块 API 请求/响应模型

// MARK: - 请求体

struct VisionItemCreateRequest: Encodable {
    let category: String
    let title: String
    let description: String
    let imageUrl: String
    let targetDate: String
}

struct VisionItemUpdateRequest: Encodable {
    let category: String?
    let title: String?
    let description: String?
    let imageUrl: String?
    let targetDate: String?
}

// MARK: - API 调用

enum VisionAPI {
    private static let base = "/api/vision"

    static func getItems(category: String? = nil, completion: @escaping (Result<[VisionItemData], Error>) -> Void) {
        var items: [URLQueryItem] = []
        if let c = category { items.append(URLQueryItem(name: "category", value: c)) }
        APIClient.shared.requestWrapped(path: "\(base)/items", method: "GET", queryItems: items.isEmpty ? nil : items, completion: completion)
    }

    static func getItem(id: String, completion: @escaping (Result<VisionItemData, Error>) -> Void) {
        APIClient.shared.requestWrapped(path: "\(base)/items/\(id)", method: "GET", completion: completion)
    }

    static func createItem(item: VisionItemData, completion: @escaping (Result<VisionItemData, Error>) -> Void) {
        let req = VisionItemCreateRequest(
            category: item.category.rawValue,
            title: item.title,
            description: item.description,
            imageUrl: item.imageUrl,
            targetDate: item.targetDate
        )
        APIClient.shared.requestWrapped(path: "\(base)/items", method: "POST", body: req, completion: completion)
    }

    static func updateItem(id: String, item: VisionItemData, completion: @escaping (Result<VisionItemData, Error>) -> Void) {
        let req = VisionItemUpdateRequest(
            category: item.category.rawValue,
            title: item.title,
            description: item.description,
            imageUrl: item.imageUrl,
            targetDate: item.targetDate.isEmpty ? nil : item.targetDate
        )
        APIClient.shared.requestWrapped(path: "\(base)/items/\(id)", method: "PUT", body: req, completion: completion)
    }

    static func deleteItem(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        APIClient.shared.requestVoid(path: "\(base)/items/\(id)", method: "DELETE", completion: completion)
    }
}
