import SwiftUI
import Foundation
import PhotosUI

@MainActor
final class VisionBoardEditorViewModel: ObservableObject {
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

    @Published var selectedPhotoItem: PhotosPickerItem? = nil
    @Published var isSaving: Bool = false
    @Published var isImageLoading: Bool = false
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

    func handlePhotoItemChanged() async {
        guard let selectedPhotoItem else { return }

        isImageLoading = true
        defer { isImageLoading = false }

        do {
            if let data = try await selectedPhotoItem.loadTransferable(type: Data.self), !data.isEmpty {
                imageSource = VisionBoardEditorImageSource.pickedData(data)
            }
        } catch {
        }

        self.selectedPhotoItem = nil
    }

    func removeImage() {
        imageSource = VisionBoardEditorImageSource.none
        selectedPhotoItem = nil
    }

    func save() async -> String? {
        guard isFormValid else { return nil }
        if isSaving { return nil }

        isSaving = true
        defer { isSaving = false }

        try? await Task.sleep(nanoseconds: 800_000_000)

        let resolvedId = (editingId?.isEmpty == false) ? (editingId ?? "") : "v-\(UUID().uuidString)"
        let resolvedImageUrl = resolvedImageUrlForStorage()

        let item = VisionItemData(
            id: resolvedId,
            category: category,
            title: clamped(titleText, max: 50),
            description: clamped(descriptionText, max: 200),
            imageUrl: resolvedImageUrl,
            targetDate: ""
        )

        service.upsertItem(item)
        return resolvedId
    }

    private func resolvedImageUrlForStorage() -> String {
        switch imageSource {
        case VisionBoardEditorImageSource.none:
            return ""
        case VisionBoardEditorImageSource.remoteUrl(let url):
            return url
        case VisionBoardEditorImageSource.pickedData(let data):
            return "data:image/jpeg;base64," + data.base64EncodedString()
        }
    }

    private func clamped(_ text: String, max: Int) -> String {
        guard max > 0 else { return "" }
        if text.count <= max { return text }
        let prefixText = text.prefix(max)
        return String(prefixText)
    }
}