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

    static func == (lhs: VirtuePracticeLogData, rhs: VirtuePracticeLogData) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}