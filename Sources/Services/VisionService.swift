import Foundation

final class VisionService {
    static let shared = VisionService()

    private var itemsById: [String: VisionItemData]
    private var cachedUserId: String?
    private var apiItemsCache: [VisionItemData] = []

    private init() {
        self.itemsById = [:]
    }

    private func currentUserId() -> String? {
        let phone = AuthService.shared.currentPhone
        guard !phone.isEmpty else { return nil }
        return UserDataPersistence.shared.sanitizedUserId(phone)
    }

    private func ensureLoaded() {
        guard let uid = currentUserId() else {
            if cachedUserId != nil {
                itemsById = [:]
                cachedUserId = nil
                apiItemsCache = []
            }
            return
        }
        if cachedUserId == uid, !APIConfig.useRealAPI { return }
        cachedUserId = uid
        if APIConfig.useRealAPI { return }
        if let list = UserDataPersistence.shared.loadVisionItems(userId: uid), !list.isEmpty {
            itemsById = Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
        } else {
            itemsById = [:]
            seedSampleItemsIfNewUser()
        }
    }

    /// 登出或切换账号时清空所有缓存，确保不泄露上一账号数据
    func clearAllCaches() {
        cachedUserId = nil
        itemsById = [:]
        apiItemsCache = []
    }

    func loadFromAPI(completion: @escaping () -> Void = {}) {
        guard APIConfig.useRealAPI else {
            ensureLoaded()
            completion()
            return
        }
        if let uid = currentUserId() {
            cachedUserId = uid
            if apiItemsCache.isEmpty, let saved = UserDataPersistence.shared.loadVisionItems(userId: uid), !saved.isEmpty {
                apiItemsCache = saved
            }
        }
        VisionAPI.getItems { [weak self] result in
            switch result {
            case .success(let list):
                self?.apiItemsCache = list
                self?.persistApiVisionIfNeeded()
                print("[VisionService] ✅ 从API加载到 \(list.count) 条愿景数据")
            case .failure:
                print("[VisionService] ⚠️ API加载愿景失败，保留上次同步到本地的数据")
            }
            DispatchQueue.main.async { completion() }
        }
    }

    private func persistApiVisionIfNeeded() {
        guard APIConfig.useRealAPI else { return }
        guard let uid = currentUserId() ?? cachedUserId else { return }
        UserDataPersistence.shared.saveVisionItems(apiItemsCache, userId: uid)
    }

    /// 新用户首次进入时写入示例愿景（含 work、growth、health、relationship），并立即持久化
    private func seedSampleItemsIfNewUser() {
        let samples: [VisionItemData] = [
            VisionItemData(
                id: "v-sample-1",
                category: .work,
                title: "成为更好的自己",
                description: "在职业上持续精进，做有价值的事。",
                imageUrl: "asset:vision_work",
                targetDate: ""
            ),
            VisionItemData(
                id: "v-sample-2",
                category: .growth,
                title: "坚持阅读与记录",
                description: "每天读书或写日记，像 Poppy 一样养成好习惯。",
                imageUrl: "asset:vision_growth",
                targetDate: ""
            ),
            VisionItemData(
                id: "v-sample-3",
                category: .health,
                title: "规律运动",
                description: "每周运动几次，保持身体和心情都棒棒的。",
                imageUrl: "asset:vision_health",
                targetDate: ""
            ),
            VisionItemData(
                id: "v-sample-4",
                category: .relationship,
                title: "珍惜身边人",
                description: "与家人朋友保持联结，用爱温暖彼此。",
                imageUrl: "asset:vision_relationship",
                targetDate: ""
            )
        ]
        for item in samples { itemsById[item.id] = item }
        saveToPersistence()
    }

    private func saveToPersistence() {
        guard let uid = cachedUserId else { return }
        let list = Array(itemsById.values)
        UserDataPersistence.shared.saveVisionItems(list, userId: uid)
    }

    func getItem(id: String) -> VisionItemData {
        if APIConfig.useRealAPI {
            if let found = apiItemsCache.first(where: { $0.id == id }) { return found }
        }
        ensureLoaded()
        if let found = itemsById[id] { return found }
        return defaultItem(id: id, category: .growth)
    }

    func getItems(category: DiaryCategoryData? = nil) -> [VisionItemData] {
        let all: [VisionItemData]
        if APIConfig.useRealAPI {
            all = apiItemsCache
        } else {
            ensureLoaded()
            all = Array(itemsById.values)
        }
        let filtered = all.filter { item in
            if let category { return item.category == category }
            return true
        }.sorted { $0.id < $1.id }

        if !filtered.isEmpty { return filtered }

        let fallbackCategory = category ?? .growth
        return [defaultItem(id: "v-fallback-\(fallbackCategory.rawValue)", category: fallbackCategory)]
    }

    func upsertItem(_ item: VisionItemData, completion: ((Result<String?, Error>) -> Void)? = nil) {
        if APIConfig.useRealAPI {
            let normalized = normalizeItem(item)
            let isUpdate = apiItemsCache.contains { $0.id == normalized.id }
            if isUpdate {
                VisionAPI.updateItem(id: normalized.id, item: normalized) { [weak self] result in
                    if case .success(let updated) = result {
                        if let idx = self?.apiItemsCache.firstIndex(where: { $0.id == updated.id }) {
                            self?.apiItemsCache[idx] = updated
                        } else {
                            self?.apiItemsCache.append(updated)
                        }
                        self?.persistApiVisionIfNeeded()
                    }
                    completion?(result.map { $0.id })
                }
            } else {
                VisionAPI.createItem(item: normalized) { [weak self] result in
                    if case .success(let created) = result {
                        self?.apiItemsCache.append(created)
                        self?.persistApiVisionIfNeeded()
                    }
                    completion?(result.map { $0.id })
                }
            }
            return
        }
        ensureLoaded()
        let normalized = normalizeItem(item)
        itemsById[normalized.id] = normalized
        saveToPersistence()
        completion?(.success(normalized.id))
    }

    func deleteItem(id: String, completion: ((Result<Void, Error>) -> Void)? = nil) {
        if APIConfig.useRealAPI {
            VisionAPI.deleteItem(id: id) { [weak self] result in
                if case .success = result {
                    self?.apiItemsCache.removeAll { $0.id == id }
                    self?.persistApiVisionIfNeeded()
                }
                completion?(result)
            }
            return
        }
        ensureLoaded()
        itemsById.removeValue(forKey: id)
        saveToPersistence()
        completion?(.success(()))
    }

    private func defaultItem(id: String, category: DiaryCategoryData) -> VisionItemData {
        let assetByCategory: [DiaryCategoryData: String] = [
            .work: "asset:vision_work",
            .growth: "asset:vision_growth",
            .health: "asset:vision_health",
            .relationship: "asset:vision_relationship",
            .daily: "asset:vision_growth"
        ]
        return VisionItemData(
            id: id,
            category: category,
            title: "添加你的愿景",
            description: "写下你想成为的样子，给未来一个清晰的方向。",
            imageUrl: assetByCategory[category] ?? "asset:vision_growth",
            targetDate: ""
        )
    }

    private func normalizeItem(_ item: VisionItemData) -> VisionItemData {
        let normalizedId = item.id.isEmpty ? "v-\(UUID().uuidString)" : item.id
        let normalizedTitle = item.title.isEmpty ? "添加你的愿景" : item.title
        let normalizedDescription = item.description.isEmpty ? "写下你想成为的样子，给未来一个清晰的方向。" : item.description
        let normalizedImageUrl = item.imageUrl.isEmpty ? defaultItem(id: normalizedId, category: item.category).imageUrl : item.imageUrl
        return VisionItemData(
            id: normalizedId,
            category: item.category,
            title: normalizedTitle,
            description: normalizedDescription,
            imageUrl: normalizedImageUrl,
            targetDate: item.targetDate
        )
    }
}