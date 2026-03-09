import SwiftUI
import PhotosUI
import UIKit

struct VisionBoardEditor: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel: VisionBoardEditorViewModel

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
                        selectedPhotoItem: $viewModel.selectedPhotoItem,
                        isDisabled: viewModel.isInputDisabled,
                        isLoading: viewModel.isImageLoading,
                        onRemove: viewModel.removeImage
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
        .onChange(of: viewModel.selectedPhotoItem) { _ in
            Task { await viewModel.handlePhotoItemChanged() }
        }
    }

    private func handleSave() {
        Task {
            let savedId = await viewModel.save()
            if savedId != nil {
                router.navigate(to: AppRouter.Destination.visionBoardMain, style: AppRouter.NavigationStyle.root)
            }
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
    @Binding var selectedPhotoItem: PhotosPickerItem?
    let isDisabled: Bool
    let isLoading: Bool
    let onRemove: () -> Void

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
                        isLoading: isLoading,
                        onReplace: { },
                        onRemove: onRemove,
                        isDisabled: isDisabled
                    )
                } else {
                    VisionBoardEditorImagePlaceholder(isDisabled: isDisabled)
                }

                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Color.clear
                }
                .disabled(isDisabled || isLoading)
                .buttonStyle(.plain)
            }
            .aspectRatio(1.0, contentMode: .fit)

            if isLoading {
                HStack(spacing: 8) {
                    SafeIcon("Loader2", size: 16, color: AppTheme.colors.onMuted)
                    Text("上传中...")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.colors.onMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
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
    let isLoading: Bool
    let onReplace: () -> Void
    let onRemove: () -> Void
    let isDisabled: Bool

    var body: some View {
        ZStack {
            previewContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.colors.muted)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.standard, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radius.standard, style: .continuous)
                        .stroke(AppTheme.colors.border, lineWidth: 2)
                )
                .clipped()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    VisionBoardEditorSmallButton(
                        title: "更换",
                        icon: "Edit2",
                        variant: ButtonVariant.secondary,
                        isDisabled: isDisabled || isLoading,
                        onTap: onReplace
                    )

                    VisionBoardEditorSmallButton(
                        title: "删除",
                        icon: "Trash2",
                        variant: ButtonVariant.destructive,
                        isDisabled: isDisabled || isLoading,
                        onTap: onRemove
                    )
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }

            if isLoading {
                Color.black.opacity(0.50)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius.standard, style: .continuous))

                SafeIcon("Loader2", size: 32, color: Color.white)
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
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
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