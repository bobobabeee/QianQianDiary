import SwiftUI
import Foundation

@MainActor
final class VisionSharePreviewViewModel: ObservableObject {
    struct VisionSharePreviewPageTemplate: Identifiable {
        enum Style {
            case minimal
            case gradient
            case artistic
            case motivational
        }

        let id: String
        let name: String
        let description: String
        let style: Style
        let icon: String
    }

    enum VisionSharePreviewPageSharePlatform {
        case wechat
        case qq
        case weibo
    }

    struct VisionSharePreviewPageToast: Identifiable {
        enum Kind {
            case success
            case error
        }

        let id: String
        let kind: Kind
        let title: String
        let message: String
    }

    @Published var visionId: String
    @Published var selectedTemplateId: String
    @Published var isClientReady: Bool = false

    @Published var isSaving: Bool = false
    @Published var isSharing: Bool = false
    @Published var isShareMenuVisible: Bool = false

    @Published var toast: VisionSharePreviewPageToast? = nil

    private let service: VisionService

    init(id: String, service: VisionService = VisionService.shared) {
        self.visionId = id
        self.service = service
        self.selectedTemplateId = "minimal"
    }

    var visions: [VisionItemData] {
        service.getItems(category: nil)
    }

    var selectedVision: VisionItemData {
        visions.first(where: { $0.id == visionId }) ?? visions.first ?? service.getItem(id: visionId)
    }

    var templates: [VisionSharePreviewPageTemplate] {
        [
            VisionSharePreviewPageTemplate(
                id: "minimal",
                name: "简约风格",
                description: "清爽简洁的设计",
                style: VisionSharePreviewPageTemplate.Style.minimal,
                icon: "Square"
            ),
            VisionSharePreviewPageTemplate(
                id: "gradient",
                name: "渐变风格",
                description: "温暖渐变背景",
                style: VisionSharePreviewPageTemplate.Style.gradient,
                icon: "Palette"
            ),
            VisionSharePreviewPageTemplate(
                id: "artistic",
                name: "艺术风格",
                description: "创意装饰设计",
                style: VisionSharePreviewPageTemplate.Style.artistic,
                icon: "Sparkles"
            ),
            VisionSharePreviewPageTemplate(
                id: "motivational",
                name: "励志风格",
                description: "鼓舞人心的排版",
                style: VisionSharePreviewPageTemplate.Style.motivational,
                icon: "Zap"
            )
        ]
    }

    var selectedTemplate: VisionSharePreviewPageTemplate {
        templates.first(where: { $0.id == selectedTemplateId }) ?? templates.first ?? VisionSharePreviewPageTemplate(
            id: "minimal",
            name: "简约风格",
            description: "清爽简洁的设计",
            style: VisionSharePreviewPageTemplate.Style.minimal,
            icon: "Square"
        )
    }

    var previewKey: String {
        "\(selectedTemplateId)-\(visionId)"
    }

    func onAppear() {
        isClientReady = false
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            self.isClientReady = true
        }
    }

    func selectVision(id: String) {
        visionId = id
    }

    func selectTemplate(id: String) {
        selectedTemplateId = id
    }

    func toggleShareMenu() {
        guard isClientReady else { return }
        guard !isSharing else { return }
        isShareMenuVisible.toggle()
    }

    func hideShareMenu() {
        isShareMenuVisible = false
    }

    func saveImage() {
        guard isClientReady else { return }
        guard !isSaving else { return }

        isSaving = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            self.isSaving = false
            self.showToast(
                kind: VisionSharePreviewPageToast.Kind.success,
                title: "已保存到相册",
                message: "分享卡片已保存到您的设备"
            )
        }
    }

    func setWallpaper() {
        guard isClientReady else { return }
        guard !isSaving else { return }

        isSaving = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            self.isSaving = false
            self.showToast(
                kind: VisionSharePreviewPageToast.Kind.success,
                title: "已设置为屏保",
                message: "每次解锁时都能看到您的愿景"
            )
        }
    }

    func share(to platform: VisionSharePreviewPageSharePlatform) {
        guard isClientReady else { return }
        guard !isSharing else { return }

        isSharing = true
        isShareMenuVisible = false

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            self.isSharing = false

            let name: String = switch platform {
            case VisionSharePreviewPageSharePlatform.wechat: "微信"
            case VisionSharePreviewPageSharePlatform.qq: "QQ"
            case VisionSharePreviewPageSharePlatform.weibo: "微博"
            }

            self.showToast(
                kind: VisionSharePreviewPageToast.Kind.success,
                title: "已分享到\(name)",
                message: "分享成功，邀请朋友一起成长"
            )
        }
    }

    func dismissToast() {
        toast = nil
    }

    private func showToast(kind: VisionSharePreviewPageToast.Kind, title: String, message: String) {
        toast = VisionSharePreviewPageToast(
            id: UUID().uuidString,
            kind: kind,
            title: title,
            message: message
        )

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if self.toast?.title == title {
                self.toast = nil
            }
        }
    }
}