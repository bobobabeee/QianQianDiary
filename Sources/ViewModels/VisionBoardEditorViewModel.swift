import SwiftUI
import Foundation
import UIKit

@MainActor
final class VisionBoardEditorViewModel: ObservableObject {
    /// 上传前 JPEG 压缩目标（字节）。需小于网关 `client_max_body_size`（Nginx 常见默认 1m，Multipart 略大于纯文件）。
    /// 服务器已调大 nginx 后，可改为 `5 * 1024 * 1024` 等与后端一致的上限。
    private static let uploadCompressedTargetMaxBytes = 900 * 1024

    enum VisionBoardEditorImageSource {
        case none
        case remoteUrl(String)
        case pickedData(Data)
    }

    struct VisionBoardEditorCategoryOption {
        let value: DiaryCategoryData
        let label: String
    }

    @Published var titleText: String = ""
    @Published var descriptionText: String = ""
    @Published var category: DiaryCategoryData = DiaryCategoryData.growth
    @Published var imageSource: VisionBoardEditorImageSource = VisionBoardEditorImageSource.none

    @Published var isSaving: Bool = false
    @Published private(set) var editingId: String? = nil

    private let service: VisionService

    init(id: String? = nil, service: VisionService = VisionService.shared) {
        self.service = service
        self.editingId = id
    }

    var categoryOptions: [VisionBoardEditorCategoryOption] {
        [
            VisionBoardEditorCategoryOption(value: DiaryCategoryData.work, label: "工作"),
            VisionBoardEditorCategoryOption(value: DiaryCategoryData.health, label: "健康"),
            VisionBoardEditorCategoryOption(value: DiaryCategoryData.relationship, label: "关系"),
            VisionBoardEditorCategoryOption(value: DiaryCategoryData.growth, label: "成长")
        ]
    }

    var titleCountText: String {
        "\(min(50, max(0, titleText.count)))/50"
    }

    var descriptionCountText: String {
        "\(min(200, max(0, descriptionText.count)))/200"
    }

    var isFormValid: Bool {
        let titleOk = !titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let descriptionOk = !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasImage: Bool = switch imageSource {
        case VisionBoardEditorImageSource.none: false
        case VisionBoardEditorImageSource.remoteUrl(let url): !url.isEmpty
        case VisionBoardEditorImageSource.pickedData(let data): !data.isEmpty
        }
        return titleOk && descriptionOk && hasImage
    }

    var isInputDisabled: Bool {
        isSaving
    }

    var primaryButtonTitle: String {
        isSaving ? "保存中..." : "保存愿景"
    }

    func loadIfNeeded() {
        guard let editingId, !editingId.isEmpty else { return }
        let item = service.getItem(id: editingId)

        titleText = item.title
        descriptionText = item.description
        category = item.category
        imageSource = item.imageUrl.isEmpty
            ? VisionBoardEditorImageSource.none
            : VisionBoardEditorImageSource.remoteUrl(item.imageUrl)
    }

    func applyPickedImageData(_ data: Data) {
        guard !data.isEmpty else { return }
        imageSource = VisionBoardEditorImageSource.pickedData(data)
    }

    func removeImage() {
        imageSource = VisionBoardEditorImageSource.none
    }

    @Published var saveError: String?

    func save() async -> String? {
        guard isFormValid else { return nil }
        if isSaving { return nil }

        isSaving = true
        saveError = nil
        defer { isSaving = false }

        let resolvedImageUrl: String
        switch imageSource {
        case .none:
            resolvedImageUrl = ""
        case .remoteUrl(let url):
            resolvedImageUrl = url
        case .pickedData(let data):
            // 注意：App 内「压缩目标」与网关 Nginx 的 client_max_body_size 是两回事。
            // 很多服务器默认 1m，1.5MB 的 JPEG 仍会 413。下面目标取较小值以便默认环境能通过；服务器调大 nginx 后可改为 5 * 1024 * 1024。
            let compressed = Self.compressImage(data: data, maxBytes: Self.uploadCompressedTargetMaxBytes)
            let uploaded = await uploadImage(data: compressed)
            guard let url = uploaded else {
                saveError = "图片上传失败：服务器拒绝了请求体（常见为 Nginx 413，网关默认常限 1MB，与 App 里压缩上限不是同一配置）。请将服务器 nginx 的 client_max_body_size 调大（例如 10m），或换一张更小的图重试。"
                return nil
            }
            ImageURLCache.shared.storeDownloadedData(compressed, for: url)
            resolvedImageUrl = url
        }

        let resolvedId = (editingId?.isEmpty == false) ? (editingId ?? "") : "v-\(UUID().uuidString)"

        let item = VisionItemData(
            id: resolvedId,
            category: category,
            title: clamped(titleText, max: 50),
            description: clamped(descriptionText, max: 200),
            imageUrl: resolvedImageUrl,
            targetDate: ""
        )

        let savedId: String? = await withCheckedContinuation { cont in
            service.upsertItem(item) { result in
                switch result {
                case .success(let id): cont.resume(returning: id)
                case .failure(let error):
                    print("[VisionEditor] ❌ 保存失败: \(error)")
                    cont.resume(returning: nil)
                }
            }
        }

        if savedId == nil {
            saveError = "保存失败，请重试"
        }
        return savedId
    }

    private func uploadImage(data: Data) async -> String? {
        await withCheckedContinuation { cont in
            UploadAPI.uploadImage(data: data) { result in
                switch result {
                case .success(let url): cont.resume(returning: url)
                case .failure: cont.resume(returning: nil)
                }
            }
        }
    }

    private static func compressImage(data: Data, maxBytes: Int) -> Data {
        guard let image = UIImage(data: data) else { return data }

        let maxDimension: CGFloat = 1280
        let size = image.size
        var scaledImage = image
        if size.width > maxDimension || size.height > maxDimension {
            let scale = min(maxDimension / size.width, maxDimension / size.height)
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: newSize)
            scaledImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        }

        var quality: CGFloat = 0.92
        var result = scaledImage.jpegData(compressionQuality: quality) ?? data
        while result.count > maxBytes, quality > 0.1 {
            quality -= 0.05
            result = scaledImage.jpegData(compressionQuality: quality) ?? result
        }

        let sizeMB = String(format: "%.2f", Double(result.count) / 1_048_576.0)
        print("[VisionEditor] 图片压缩完成: \(sizeMB) MB (quality=\(String(format: "%.2f", quality)))，目标上限: \(maxBytes / 1024)KB")
        return result
    }

    private func clamped(_ text: String, max: Int) -> String {
        guard max > 0 else { return "" }
        if text.count <= max { return text }
        let prefixText = text.prefix(max)
        return String(prefixText)
    }
}