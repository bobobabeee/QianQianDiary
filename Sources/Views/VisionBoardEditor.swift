import SwiftUI
import Photos
import PhotosUI
import UIKit
import UniformTypeIdentifiers

struct VisionBoardEditor: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel: VisionBoardEditorViewModel

    @AppStorage("VisionBoardPhotoLibraryRationaleAcknowledged") private var photoLibraryRationaleAcknowledged = false
    @State private var showPhotoLibraryRationaleAlert = false
    @State private var showVisionPhotoPickerSheet = false

    init(id: String? = nil) {
        _viewModel = StateObject(wrappedValue: VisionBoardEditorViewModel(id: id))
    }

    var body: some View {
        VStack(spacing: 0) {
            MobileHeader(title: "编辑愿景", showBack: true)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    VisionBoardEditorImageUploadSection(
                        imageSource: viewModel.imageSource,
                        isDisabled: viewModel.isInputDisabled,
                        onRemove: viewModel.removeImage,
                        onRequestPhotoPick: requestVisionPhotoPick
                    )

                    VisionBoardEditorTextFieldSection(
                        title: "愿景标题",
                        placeholder: "例如:成为高级架构师",
                        text: $viewModel.titleText,
                        countText: viewModel.titleCountText,
                        isDisabled: viewModel.isInputDisabled
                    )

                    VisionBoardEditorTextareaSection(
                        title: "愿景描述",
                        placeholder: "详细描述你的愿景和目标...",
                        text: $viewModel.descriptionText,
                        countText: viewModel.descriptionCountText,
                        isDisabled: viewModel.isInputDisabled
                    )

                    VisionBoardEditorCategorySection(
                        selection: $viewModel.category,
                        options: viewModel.categoryOptions,
                        isDisabled: viewModel.isInputDisabled
                    )

                    VisionBoardEditorTipCard()

                    VisionBoardEditorActionButtons(
                        isCancelDisabled: viewModel.isInputDisabled,
                        isSaveDisabled: !viewModel.isFormValid || viewModel.isInputDisabled,
                        isSaving: viewModel.isSaving,
                        primaryTitle: viewModel.primaryButtonTitle,
                        onCancel: { router.dismiss() },
                        onSave: handleSave
                    )
                }
                .padding(.horizontal, AppTheme.spacing.screenHorizontal)
                .padding(.vertical, AppTheme.spacing.lg)
                .frame(maxWidth: 384)
                .frame(maxWidth: .infinity)
            }
        }
        .background(AppTheme.colors.background)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.loadIfNeeded()
        }
        .alert("访问相册", isPresented: $showPhotoLibraryRationaleAlert) {
            Button("取消", role: .cancel) {}
            Button("去选择照片") {
                photoLibraryRationaleAcknowledged = true
                showPhotoLibraryRationaleAlert = false
                DispatchQueue.main.async {
                    showVisionPhotoPickerSheet = true
                }
            }
        } message: {
            Text("我们需要访问您的相册，以便您可以选择并上传照片到您的「愿景板」中。")
        }
        .sheet(isPresented: $showVisionPhotoPickerSheet) {
            VisionBoardPHPickerRepresentable(
                isPresented: $showVisionPhotoPickerSheet,
                onPicked: { data in viewModel.applyPickedImageData(data) }
            )
            .ignoresSafeArea()
        }
        .alert("提示", isPresented: Binding(
            get: { viewModel.saveError != nil },
            set: { if !$0 { viewModel.saveError = nil } }
        )) {
            Button("确定", role: .cancel) { viewModel.saveError = nil }
        } message: {
            Text(viewModel.saveError ?? "")
        }
    }

    private func handleSave() {
        Task {
            let savedId = await viewModel.save()
            if savedId != nil {
                // 保存成功后通知 VisionService 刷新缓存，并使用 root 导航重新加载展示页
                // 这样外部的愿景板预览（首页 + 愿景板主页面）都能看到最新上传的图片
                VisionService.shared.loadFromAPI {
                    print("[VisionBoardEditor] 保存成功，已触发全局数据刷新")
                }
                router.navigate(to: AppRouter.Destination.visionBoardMain, style: AppRouter.NavigationStyle.root)
            }
        }
    }

    private func requestVisionPhotoPick() {
        if photoLibraryRationaleAcknowledged {
            showVisionPhotoPickerSheet = true
        } else {
            showPhotoLibraryRationaleAlert = true
        }
    }
}

private struct VisionBoardEditorTextFieldSection: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let countText: String
    let isDisabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AppLabel(title)
                .font(size: 16, weight: .semibold)
                .textColor(AppTheme.colors.onSurface)
                .disabled(isDisabled)

            AppInput(text: $text, placeholder: placeholder)
                .height(44)
                .fontSize(16)
                .cornerRadius(AppTheme.radius.standard)
                .borderColor(AppTheme.colors.border)
                .focusRingColor(AppTheme.colors.primary)
                .textColor(AppTheme.colors.onSurface)
                .disabled(isDisabled)

            Text(countText)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.colors.onMuted)
        }
    }
}

private struct VisionBoardEditorTextareaSection: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let countText: String
    let isDisabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AppLabel(title)
                .font(size: 16, weight: .semibold)
                .textColor(AppTheme.colors.onSurface)
                .disabled(isDisabled)

            AppTextarea(text: $text, placeholder: placeholder)
                .minHeight(96)
                .fontSize(16)
                .cornerRadius(AppTheme.radius.standard)
                .borderColor(AppTheme.colors.border)
                .focusRingColor(AppTheme.colors.primary)
                .textColor(AppTheme.colors.onSurface)
                .placeholderColor(AppTheme.colors.onMuted.opacity(0.6))
                .disabled(isDisabled)

            Text(countText)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.colors.onMuted)
        }
    }
}

private struct VisionBoardEditorCategorySection: View {
    @Binding var selection: DiaryCategoryData
    let options: [VisionBoardEditorViewModel.VisionBoardEditorCategoryOption]
    let isDisabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AppLabel("分类")
                .font(size: 16, weight: .semibold)
                .textColor(AppTheme.colors.onSurface)
                .disabled(isDisabled)

            AppSelect(
                selection: $selection,
                displayValue: displayLabel
            ) {
                ForEach(options, id: \.label) { option in
                    AppSelectItem(value: option.value, label: option.label)
                        .fontSize(16)
                        .textColor(AppTheme.colors.onSurface)
                }
            }
            .fontSize(16)
            .height(44)
            .cornerRadius(AppTheme.radius.standard)
            .borderColor(AppTheme.colors.border)
            .background(AppTheme.colors.surface)
            .accentColor(AppTheme.colors.muted)
            .disabled(isDisabled)
        }
    }

    private var displayLabel: String? {
        options.first(where: { $0.value == selection })?.label
    }
}

private struct VisionBoardEditorTipCard: View {
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 8) {
                    SafeIcon("Lightbulb", size: 18, color: AppTheme.colors.secondary)
                        .padding(.top, 2)

                    Text("将你的梦想视觉化,每天看到它会增强你的行动力。选择一张能代表你愿景的图片,配上清晰的描述。")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.colors.onSurface)
                        .lineSpacing(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(AppTheme.colors.secondary.opacity(0.20))
        .borderColor(AppTheme.colors.secondary.opacity(0.30))
        .cornerRadius(AppTheme.radius.standard)
        .shadow(color: AppTheme.shadow.soft.color, radius: AppTheme.shadow.soft.radius)
    }
}

private struct VisionBoardEditorActionButtons: View {
    let isCancelDisabled: Bool
    let isSaveDisabled: Bool
    let isSaving: Bool
    let primaryTitle: String
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AppButton("取消", action: onCancel)
                .variant(ButtonVariant.outline)
                .cornerRadius(AppTheme.radius.standard)
                .height(44)
                .foregroundColor(AppTheme.colors.onSurface)
                .disabled(isCancelDisabled)
                .frame(maxWidth: .infinity)

            AppButton(action: onSave) {
                HStack(spacing: 8) {
                    if isSaving {
                        SafeIcon("Loader2", size: 18, color: AppTheme.colors.onPrimary)
                    }
                    Text(primaryTitle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .cornerRadius(AppTheme.radius.standard)
            .height(44)
            .backgroundColor(AppTheme.colors.primary)
            .foregroundColor(AppTheme.colors.onPrimary)
            .disabled(isSaveDisabled)
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 16)
    }
}

private struct VisionBoardEditorImageUploadSection: View {
    let imageSource: VisionBoardEditorViewModel.VisionBoardEditorImageSource
    let isDisabled: Bool
    let onRemove: () -> Void
    let onRequestPhotoPick: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AppLabel("愿景图片")
                .font(size: 16, weight: .semibold)
                .textColor(AppTheme.colors.onSurface)
                .disabled(isDisabled)

            ZStack {
                if hasImage {
                    VisionBoardEditorImagePreview(
                        imageSource: imageSource,
                        onRemove: onRemove,
                        isDisabled: isDisabled,
                        onRequestPhotoPick: onRequestPhotoPick
                    )
                } else {
                    VisionBoardEditorImagePlaceholder(isDisabled: isDisabled)
                        .overlay {
                            Button(action: onRequestPhotoPick) {
                                Color.clear
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(isDisabled)
                            .allowsHitTesting(!isDisabled)
                        }
                }
            }
            .aspectRatio(1.0, contentMode: .fit)
        }
    }

    private var hasImage: Bool {
        switch imageSource {
        case VisionBoardEditorViewModel.VisionBoardEditorImageSource.none:
            return false
        case VisionBoardEditorViewModel.VisionBoardEditorImageSource.remoteUrl(let url):
            return !url.isEmpty
        case VisionBoardEditorViewModel.VisionBoardEditorImageSource.pickedData(let data):
            return !data.isEmpty
        }
    }
}

private struct VisionBoardEditorImagePreview: View {
    let imageSource: VisionBoardEditorViewModel.VisionBoardEditorImageSource
    let onRemove: () -> Void
    let isDisabled: Bool
    let onRequestPhotoPick: () -> Void

    var body: some View {
        ZStack {
            previewContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.colors.muted)
                .contentShape(RoundedRectangle(cornerRadius: AppTheme.radius.standard, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.standard, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radius.standard, style: .continuous)
                        .stroke(AppTheme.colors.border, lineWidth: 2)
                )

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    Button(action: onRequestPhotoPick) {
                        HStack(spacing: 6) {
                            SafeIcon("Edit2", size: 16, color: AppTheme.colors.onSecondary)
                            Text("更换")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.colors.onSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.colors.secondary)
                        .cornerRadius(AppTheme.radius.small)
                    }
                    .disabled(isDisabled)
                    .buttonStyle(.plain)

                    VisionBoardEditorSmallButton(
                        title: "删除",
                        icon: "Trash2",
                        variant: ButtonVariant.destructive,
                        isDisabled: isDisabled,
                        onTap: onRemove
                    )
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .accessibilityLabel(Text("愿景图片预览"))
    }

    @ViewBuilder
    private var previewContent: some View {
        switch imageSource {
        case VisionBoardEditorViewModel.VisionBoardEditorImageSource.none:
            AppTheme.colors.muted

        case VisionBoardEditorViewModel.VisionBoardEditorImageSource.remoteUrl(let url):
            VisionImage.card(urlOrAsset: url, aspectRatio: 1.0)
                .contentMode(RemoteImageContentMode.fill)

        case VisionBoardEditorViewModel.VisionBoardEditorImageSource.pickedData(let data):
            if let uiImage = UIImage(data: data) {
                GeometryReader { geo in
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
            } else {
                AppTheme.colors.muted
            }
        }
    }
}

private struct VisionBoardEditorImagePlaceholder: View {
    let isDisabled: Bool

    var body: some View {
        VStack(spacing: 8) {
            SafeIcon("Upload", size: 32, color: AppTheme.colors.onMuted)

            VStack(spacing: 4) {
                Text("点击上传图片")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.colors.onSurface)

                Text("或拖拽图片到此处")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.colors.onMuted)
            }

            Text("支持 JPG、PNG、WebP 格式,最大 5MB")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.colors.onMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.colors.muted.opacity(isDisabled ? 0.20 : 0.30))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.standard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radius.standard, style: .continuous)
                .stroke(AppTheme.colors.border, style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
        )
        .contentShape(Rectangle())
        .accessibilityLabel(Text("点击上传图片"))
    }
}

private struct VisionBoardEditorSmallButton: View {
    let title: String
    let icon: String
    let variant: ButtonVariant
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        AppButton(action: onTap) {
            HStack(spacing: 6) {
                SafeIcon(icon, size: 16, color: foregroundColor)
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .variant(variant)
        .size(ButtonSize.small)
        .cornerRadius(AppTheme.radius.small)
        .disabled(isDisabled)
        .backgroundColor(backgroundColor)
        .foregroundColor(foregroundColor)
    }

    private var backgroundColor: Color {
        switch variant {
        case ButtonVariant.secondary:
            return AppTheme.colors.secondary
        case ButtonVariant.destructive:
            return AppTheme.colors.error
        default:
            return AppTheme.colors.muted
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case ButtonVariant.secondary:
            return AppTheme.colors.onSecondary
        case ButtonVariant.destructive:
            return AppTheme.colors.onError
        default:
            return AppTheme.colors.onSurface
        }
    }
}

// MARK: - 系统相册选择（首次说明后使用 PHPicker，触发系统相册权限）

private struct VisionBoardPHPickerRepresentable: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onPicked: (Data) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: VisionBoardPHPickerRepresentable

        init(_ parent: VisionBoardPHPickerRepresentable) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false
            guard let first = results.first else { return }
            let provider = first.itemProvider
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                    DispatchQueue.main.async {
                        guard let self, let uiImage = image as? UIImage else { return }
                        if let jpeg = uiImage.jpegData(compressionQuality: 0.92) {
                            self.parent.onPicked(jpeg)
                        } else if let png = uiImage.pngData() {
                            self.parent.onPicked(png)
                        }
                    }
                }
            } else {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, _ in
                    DispatchQueue.main.async {
                        guard let self, let data, !data.isEmpty else { return }
                        self.parent.onPicked(data)
                    }
                }
            }
        }
    }
}