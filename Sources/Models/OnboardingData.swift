import Foundation

final class DialogStepData: Codable, Identifiable, Hashable {
    var id: Int
    var characterName: String
    var text: String
    var avatarUrl: String

    init(id: Int, characterName: String, text: String, avatarUrl: String) {
        self.id = id
        self.characterName = characterName
        self.text = text
        self.avatarUrl = avatarUrl
    }

    static func == (lhs: DialogStepData, rhs: DialogStepData) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

final class MetaphorStoryData: Codable, Hashable {
    var characterName: String
    var dialogs: [String]
    var illustrationUrl: String

    init(characterName: String, dialogs: [String], illustrationUrl: String) {
        self.characterName = characterName
        self.dialogs = dialogs
        self.illustrationUrl = illustrationUrl
    }

    static func == (lhs: MetaphorStoryData, rhs: MetaphorStoryData) -> Bool {
        lhs.characterName == rhs.characterName &&
            lhs.dialogs == rhs.dialogs &&
            lhs.illustrationUrl == rhs.illustrationUrl
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(characterName)
        hasher.combine(dialogs)
        hasher.combine(illustrationUrl)
    }
}