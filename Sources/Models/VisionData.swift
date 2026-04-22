import Foundation

final class VisionItemData: Codable, Identifiable, Hashable {
    var id: String
    var category: DiaryCategoryData
    var title: String
    var description: String
    var imageUrl: String
    var targetDate: String

    private enum CodingKeys: String, CodingKey {
        case id, category, title, description, imageUrl, targetDate
    }

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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let intId = try? container.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else {
            self.id = (try? container.decode(String.self, forKey: .id)) ?? ""
        }
        self.category = (try? container.decode(DiaryCategoryData.self, forKey: .category)) ?? .daily
        self.title = (try? container.decode(String.self, forKey: .title)) ?? ""
        self.description = (try? container.decode(String.self, forKey: .description)) ?? ""
        self.imageUrl = (try? container.decode(String.self, forKey: .imageUrl)) ?? ""
        self.targetDate = (try? container.decode(String.self, forKey: .targetDate)) ?? ""
    }

    static func == (lhs: VisionItemData, rhs: VisionItemData) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}