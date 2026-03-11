import Foundation

final class VirtueService {
    static let shared = VirtueService()

    private var definitionsByType: [VirtueTypeData: VirtueDefinitionData]
    private var logsById: [String: VirtuePracticeLogData]
    private var cachedUserId: String?

    private init() {
        let definitions: [VirtueDefinitionData] = [
            VirtueDefinitionData(
                id: "virtue-friendly",
                type: .friendly,
                name: "友好亲和",
                quote: "最美好的事情莫过于温和待人。",
                guidelines: ["祝愿他人生活幸福", "不伤害他人，不介入纷争", "谦虚尊重他人，我不必永远正确"],
                iconName: "Smile"
            ),
            VirtueDefinitionData(
                id: "virtue-responsible",
                type: .responsible,
                name: "勇于承担",
                quote: "最美好的事情莫过于直面责任。",
                guidelines: ["遇事坚定自主抉择", "专注自身能做的事", "主动承担责任，赋予自我权力"],
                iconName: "ShieldCheck"
            ),
            VirtueDefinitionData(
                id: "virtue-kind",
                type: .kind,
                name: "善待他人",
                quote: "最美好的事情莫过于温暖待人。",
                guidelines: ["多称赞他人，沉默也比伤人好", "不随意批评身边的人", "用心聚焦他人的优点"],
                iconName: "HeartHandshake"
            ),
            VirtueDefinitionData(
                id: "virtue-helpful",
                type: .helpful,
                name: "帮助给予",
                quote: "最美好的事情莫过于帮助他人。",
                guidelines: ["祝愿身边的人一切顺利", "主动表达善意与温暖", "把帮助别人当作最大的快乐"],
                iconName: "HandHelping"
            ),
            VirtueDefinitionData(
                id: "virtue-grateful",
                type: .grateful,
                name: "感恩之心",
                quote: "最美好的事情莫过于心怀感激。",
                guidelines: ["感恩生活中的日常小事", "在困境中积极寻找希望", "珍惜身边的每一份陪伴"],
                iconName: "Grape"
            ),
            VirtueDefinitionData(
                id: "virtue-learning",
                type: .learning,
                name: "勤学不辍",
                quote: "最美好的事情莫过于持续成长。",
                guidelines: ["始终保持谦恭好学的心态", "坚持读书、记录，向他人学习", "只与过去的自己较劲，持续进化"],
                iconName: "BookOpen"
            ),
            VirtueDefinitionData(
                id: "virtue-reliable",
                type: .reliable,
                name: "值得信赖",
                quote: "最美好的事情莫过于信守承诺。",
                guidelines: ["用良好习惯成就更好的自己", "坚信自律比天赋更为重要", "始终守时守信，信守每一个承诺"],
                iconName: "Award"
            )
        ]

        self.definitionsByType = Dictionary(uniqueKeysWithValues: definitions.map { ($0.type, $0) })
        self.logsById = [:]
    }

    private func currentUserId() -> String? {
        let phone = AuthService.shared.currentPhone
        guard !phone.isEmpty else { return nil }
        return UserDataPersistence.shared.sanitizedUserId(phone)
    }

    private func ensureLoaded() {
        guard let uid = currentUserId() else {
            if cachedUserId != nil {
                logsById = [:]
                cachedUserId = nil
            }
            return
        }
        if cachedUserId == uid { return }
        cachedUserId = uid
        if let list = UserDataPersistence.shared.loadVirtueLogs(userId: uid), !list.isEmpty {
            logsById = Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
        } else {
            logsById = [:]
            seedSampleLogIfNewUser()
        }
    }

    /// 新用户首次进入时写入一条示例美德践行记录，并立即持久化
    private func seedSampleLogIfNewUser() {
        let today = currentDateString()
        let todayVirtue = getTodayVirtueDefinition()
        let sample = VirtuePracticeLogData(
            id: "log-sample-\(today)-\(todayVirtue.type.rawValue)",
            date: today,
            virtueType: todayVirtue.type,
            isCompleted: true,
            reflection: "今天也有意识地践行了「\(todayVirtue.name)」，从小事做起。"
        )
        logsById[sample.id] = sample
        saveToPersistence()
    }

    private func saveToPersistence() {
        guard let uid = cachedUserId else { return }
        let list = Array(logsById.values)
        UserDataPersistence.shared.saveVirtueLogs(list, userId: uid)
    }

    func getVirtueDefinition(type: VirtueTypeData) -> VirtueDefinitionData {
        if let found = definitionsByType[type] { return found }
        return defaultVirtueDefinition(type: type)
    }

    func getAllVirtueDefinitions() -> [VirtueDefinitionData] {
        VirtueTypeData.allCases.map { getVirtueDefinition(type: $0) }
    }

    func getTodayVirtueDefinition(date: Date = Date(), calendar: Calendar = .current) -> VirtueDefinitionData {
        let day = calendar.component(.day, from: date)
        let types = VirtueTypeData.allCases
        let type = types[abs(day) % max(types.count, 1)]
        return getVirtueDefinition(type: type)
    }

    func getVirtuePracticeLog(id: String) -> VirtuePracticeLogData {
        ensureLoaded()
        if let found = logsById[id] { return found }
        return defaultVirtuePracticeLog(id: id, date: currentDateString(), virtueType: getTodayVirtueDefinition().type)
    }

    func getVirtuePracticeLogs(date: String? = nil, virtueType: VirtueTypeData? = nil) -> [VirtuePracticeLogData] {
        ensureLoaded()
        let all = Array(logsById.values)
        let filtered = all.filter { log in
            if let date, log.date != date { return false }
            if let virtueType, log.virtueType != virtueType { return false }
            return true
        }
        if !filtered.isEmpty { return filtered }

        let fallbackDate = date ?? currentDateString()
        let fallbackType = virtueType ?? getTodayVirtueDefinition().type
        return [defaultVirtuePracticeLog(id: "log-fallback-\(fallbackDate)-\(fallbackType.rawValue)", date: fallbackDate, virtueType: fallbackType)]
    }

    func upsertVirtuePracticeLog(_ log: VirtuePracticeLogData) {
        ensureLoaded()
        let normalized = normalizeVirtuePracticeLog(log)
        logsById[normalized.id] = normalized
        saveToPersistence()
    }

    func setVirtueCompleted(date: String, virtueType: VirtueTypeData, isCompleted: Bool, reflection: String = "") -> VirtuePracticeLogData {
        let existing = getVirtuePracticeLogs(date: date, virtueType: virtueType).first
        let id = existing?.id ?? "log-\(date)-\(virtueType.rawValue)"
        let updated = VirtuePracticeLogData(
            id: id,
            date: date,
            virtueType: virtueType,
            isCompleted: isCompleted,
            reflection: reflection
        )
        upsertVirtuePracticeLog(updated)
        return updated
    }

    private func defaultVirtueDefinition(type: VirtueTypeData) -> VirtueDefinitionData {
        VirtueDefinitionData(
            id: "virtue-\(type.rawValue.lowercased())",
            type: type,
            name: "未命名美德",
            quote: "今天也值得被温柔对待。",
            guidelines: ["从一个小行动开始", "把注意力放回自己能做到的事", "给自己一点肯定"],
            iconName: "Smile"
        )
    }

    private func defaultVirtuePracticeLog(id: String, date: String, virtueType: VirtueTypeData) -> VirtuePracticeLogData {
        VirtuePracticeLogData(
            id: id,
            date: date,
            virtueType: virtueType,
            isCompleted: false,
            reflection: ""
        )
    }

    private func normalizeVirtuePracticeLog(_ log: VirtuePracticeLogData) -> VirtuePracticeLogData {
        let normalizedId = log.id.isEmpty ? "log-\(UUID().uuidString)" : log.id
        let normalizedDate = log.date.isEmpty ? currentDateString() : log.date
        let normalizedReflection = log.reflection
        return VirtuePracticeLogData(
            id: normalizedId,
            date: normalizedDate,
            virtueType: log.virtueType,
            isCompleted: log.isCompleted,
            reflection: normalizedReflection
        )
    }

    private func currentDateString(date: Date = Date(), calendar: Calendar = .current) -> String {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}