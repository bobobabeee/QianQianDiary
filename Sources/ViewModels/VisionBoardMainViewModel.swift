import SwiftUI
import Foundation

@MainActor
final class VisionBoardMainViewModel: ObservableObject {
    enum VisionBoardMainCategoryFilter: Equatable {
        case all
        case category(DiaryCategoryData)

        var id: String {
            switch self {
            case VisionBoardMainCategoryFilter.all:
                return "ALL"
            case VisionBoardMainCategoryFilter.category(let category):
                return "CATEGORY-\(category.rawValue)"
            }
        }
    }

    @Published var selectedFilter: VisionBoardMainCategoryFilter = VisionBoardMainCategoryFilter.all
    @Published private var visions: [VisionItemData] = []
    @Published var pendingDeleteVisionId: String? = nil

    private let service: VisionService

    init(service: VisionService = VisionService.shared) {
        self.service = service
        load()
    }

    var categoryFilters: [VisionBoardMainCategoryFilter] {
        [
            VisionBoardMainCategoryFilter.all,
            VisionBoardMainCategoryFilter.category(.work),
            VisionBoardMainCategoryFilter.category(.health),
            VisionBoardMainCategoryFilter.category(.relationship),
            VisionBoardMainCategoryFilter.category(.growth)
        ]
    }

    var filteredVisions: [VisionItemData] {
        switch selectedFilter {
        case VisionBoardMainCategoryFilter.all:
            return visions
        case VisionBoardMainCategoryFilter.category(let category):
            return visions.filter { $0.category == category }
        }
    }

    func load() {
        visions = service.getItems(category: nil)
    }

    func selectFilter(_ filter: VisionBoardMainCategoryFilter) {
        selectedFilter = filter
    }

    func requestDelete(visionId: String) {
        pendingDeleteVisionId = visionId
    }

    func confirmDelete() {
        guard let id = pendingDeleteVisionId, !id.isEmpty else {
            pendingDeleteVisionId = nil
            return
        }
        service.deleteItem(id: id)
        pendingDeleteVisionId = nil
        load()
    }

    func cancelDelete() {
        pendingDeleteVisionId = nil
    }

    func label(for filter: VisionBoardMainCategoryFilter) -> String {
        switch filter {
        case VisionBoardMainCategoryFilter.all:
            return "全部"
        case VisionBoardMainCategoryFilter.category(let category):
            return label(for: category)
        }
    }

func label(for category: DiaryCategoryData) -> String {
        switch category {
        case DiaryCategoryData.work:
            return "工作"
        case DiaryCategoryData.health:
            return "健康"
        case DiaryCategoryData.relationship:
            return "关系"
        case DiaryCategoryData.growth:
            return "成长"
        case DiaryCategoryData.daily:
            return "日常"
        }
    }
}