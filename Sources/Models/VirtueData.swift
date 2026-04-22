import Foundation

enum VirtueTypeData: String, CaseIterable, Codable {
    case friendly = "FRIENDLY"
    case responsible = "RESPONSIBLE"
    case kind = "KIND"
    case helpful = "HELPFUL"
    case grateful = "GRATEFUL"
    case learning = "LEARNING"
    case reliable = "RELIABLE"
}

final class VirtueDefinitionData: Codable, Identifiable, Hashable {
    var id: String
    var type: VirtueTypeData
    var name: String
    var quote: String
    var guidelines: [String]
    var iconName: String

    private enum CodingKeys: String, CodingKey {
        case id, type, name, quote, guidelines, iconName
    }

    init(
        id: String,
        type: VirtueTypeData,
        name: String,
        quote: String,
        guidelines: [String],
        iconName: String
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.quote = quote
        self.guidelines = guidelines
        self.iconName = iconName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let intId = try? container.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else {
            self.id = try container.decode(String.self, forKey: .id)
        }
        self.type = (try? container.decode(VirtueTypeData.self, forKey: .type)) ?? .friendly
        self.name = (try? container.decode(String.self, forKey: .name)) ?? ""
        self.quote = (try? container.decode(String.self, forKey: .quote)) ?? ""
        self.guidelines = (try? container.decode([String].self, forKey: .guidelines)) ?? []
        self.iconName = (try? container.decode(String.self, forKey: .iconName)) ?? "Smile"
    }

    static func == (lhs: VirtueDefinitionData, rhs: VirtueDefinitionData) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

final class VirtuePracticeLogData: Codable, Identifiable, Hashable {
    var id: String
    var date: String
    var virtueType: VirtueTypeData
    var isCompleted: Bool
    var reflection: String

    private enum CodingKeys: String, CodingKey {
        case id, date, virtueType, isCompleted, reflection
    }

    init(
        id: String,
        date: String,
        virtueType: VirtueTypeData,
        isCompleted: Bool,
        reflection: String
    ) {
        self.id = id
        self.date = date
        self.virtueType = virtueType
        self.isCompleted = isCompleted
        self.reflection = reflection
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let intId = try? container.decode(Int.self, forKey: .id) {
            self.id = String(intId)
        } else {
            self.id = (try? container.decode(String.self, forKey: .id)) ?? ""
        }
        self.date = (try? container.decode(String.self, forKey: .date)) ?? ""
        self.virtueType = (try? container.decode(VirtueTypeData.self, forKey: .virtueType)) ?? .friendly
        if let boolVal = try? container.decode(Bool.self, forKey: .isCompleted) {
            self.isCompleted = boolVal
        } else if let intVal = try? container.decode(Int.self, forKey: .isCompleted) {
            self.isCompleted = intVal != 0
        } else {
            self.isCompleted = false
        }
        self.reflection = (try? container.decode(String.self, forKey: .reflection)) ?? ""
    }

    static func == (lhs: VirtuePracticeLogData, rhs: VirtuePracticeLogData) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}