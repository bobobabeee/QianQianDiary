import Foundation

final class VisionItemData: Codable, Identifiable, Hashable {
    var id: String
    var category: DiaryCategoryData
    var title: String
    var description: String
    var imageUrl: String
    var targetDate: String

    init(
        id: String,
        category: DiaryCategoryData,
        title: String,
        description: String,
        imageUrl: String,
        targetDate: String
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
        self.targetDate = targetDate
    }

    static func == (lhs: VisionItemData, rhs: VisionItemData) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}