import Foundation

final class OnboardingService {
    static let shared = OnboardingService()

    private var stepsById: [Int: DialogStepData]
    private var metaphorStory: MetaphorStoryData

    private init() {
        let steps: [DialogStepData] = [
            DialogStepData(
                id: 1,
                characterName: "钱钱",
                text: "嗨，我叫钱钱。这是一本属于你的本子——成功日记本。",
                avatarUrl: "https://spark-builder.s3.cn-north-1.amazonaws.com.cn/image/2026/3/4/04b76727-47fe-49ec-a42b-f66066ece7b5.png"
            ),
            DialogStepData(
                id: 2,
                characterName: "钱钱",
                text: "从今天起，每天记下至少5件你做成的事。任何小事都算：早起、微笑、专注工作/学习半小时……",
                avatarUrl: "https://spark-builder.s3.cn-north-1.amazonaws.com.cn/image/2026/3/4/c1693069-d7a1-42a7-8584-b5dcd4d533ec.png"
            ),
            DialogStepData(
                id: 3,
                characterName: "钱钱",
                text: "看！是汉内坎普夫妇送来的甜甜圈！点击它看看脑海里会浮现什么？",
                avatarUrl: "https://spark-builder.s3.cn-north-1.amazonaws.com.cn/image/2026/3/4/43504b2d-695e-4d30-9f94-d13ab457c6c5.png"
            )
        ]
        self.stepsById = Dictionary(uniqueKeysWithValues: steps.map { ($0.id, $0) })

        self.metaphorStory = MetaphorStoryData(
            characterName: "汉内坎普夫妇",
            dialogs: [
                "甜甜圈中间的圆孔代表着人类的内心，可是这内心本身却是无形的。",
                "许多人并不关心自己的内心，就是因为看不到它。对于他们来说，只有看得见的成功才是重要的。",
                "但你如果想要变得幸福，就不能只重视物质上的成功，还必须培养自己具有优秀的内心。",
                "没有圆圈也就没有圆孔。绝不能忽视圆圈，否则的话内心也无法彰显出来。完满而幸福的人都是两者兼备的。"
            ],
            illustrationUrl: "https://spark-builder.s3.cn-north-1.amazonaws.com.cn/image/2026/3/4/f3f597c2-42b3-442a-b416-a2e353d3e13c.png"
        )
    }

    func getOnboardingSteps() -> [DialogStepData] {
        let list = stepsById.values.sorted { $0.id < $1.id }
        if !list.isEmpty { return list }
        return [defaultStep(id: 1)]
    }

    func getStep(id: Int) -> DialogStepData {
        if let found = stepsById[id] { return found }
        return defaultStep(id: id)
    }

    func getNextStep(after id: Int) -> DialogStepData {
        let ids = stepsById.keys.sorted()
        if let index = ids.firstIndex(of: id), index + 1 < ids.count {
            return getStep(id: ids[index + 1])
        }
        if let first = ids.first {
            return getStep(id: first)
        }
        return defaultStep(id: id + 1)
    }

    func getMetaphorStory() -> MetaphorStoryData {
        let dialogs = metaphorStory.dialogs.isEmpty ? defaultMetaphorStory().dialogs : metaphorStory.dialogs
        let characterName = metaphorStory.characterName.isEmpty ? defaultMetaphorStory().characterName : metaphorStory.characterName
        let illustrationUrl = metaphorStory.illustrationUrl.isEmpty ? defaultMetaphorStory().illustrationUrl : metaphorStory.illustrationUrl
        return MetaphorStoryData(characterName: characterName, dialogs: dialogs, illustrationUrl: illustrationUrl)
    }

    func upsertStep(_ step: DialogStepData) {
        let normalized = normalizeStep(step)
        stepsById[normalized.id] = normalized
    }

    func setMetaphorStory(_ story: MetaphorStoryData) {
        let normalized = normalizeMetaphorStory(story)
        metaphorStory = normalized
    }

    private func defaultStep(id: Int) -> DialogStepData {
        DialogStepData(
            id: id,
            characterName: "钱钱",
            text: "我们从一个小目标开始：记录今天的一件小成功。",
            avatarUrl: "https://spark-builder.s3.cn-north-1.amazonaws.com.cn/image/2026/3/4/04b76727-47fe-49ec-a42b-f66066ece7b5.png"
        )
    }

    private func normalizeStep(_ step: DialogStepData) -> DialogStepData {
        let normalizedCharacter = step.characterName.isEmpty ? "钱钱" : step.characterName
        let normalizedText = step.text.isEmpty ? "我们从一个小目标开始：记录今天的一件小成功。" : step.text
        let normalizedAvatar = step.avatarUrl.isEmpty ? defaultStep(id: step.id).avatarUrl : step.avatarUrl
        return DialogStepData(id: step.id, characterName: normalizedCharacter, text: normalizedText, avatarUrl: normalizedAvatar)
    }

    private func defaultMetaphorStory() -> MetaphorStoryData {
        MetaphorStoryData(
            characterName: "汉内坎普夫妇",
            dialogs: [
                "你看见的成就很重要，你看不见的内心也同样重要。",
                "两者兼备，才能更接近幸福。"
            ],
            illustrationUrl: "https://spark-builder.s3.cn-north-1.amazonaws.com.cn/image/2026/3/4/f3f597c2-42b3-442a-b416-a2e353d3e13c.png"
        )
    }

    private func normalizeMetaphorStory(_ story: MetaphorStoryData) -> MetaphorStoryData {
        let fallback = defaultMetaphorStory()
        let characterName = story.characterName.isEmpty ? fallback.characterName : story.characterName
        let dialogs = story.dialogs.isEmpty ? fallback.dialogs : story.dialogs
        let illustrationUrl = story.illustrationUrl.isEmpty ? fallback.illustrationUrl : story.illustrationUrl
        return MetaphorStoryData(characterName: characterName, dialogs: dialogs, illustrationUrl: illustrationUrl)
    }
}