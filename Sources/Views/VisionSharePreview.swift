import SwiftUI

struct VisionSharePreview: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel: VisionSharePreviewViewModel

    init(id: String) {
        _viewModel = StateObject(wrappedValue: VisionSharePreviewViewModel(id: id))
    }

    var body: some View {
        VStack(spacing: 0) {
            MobileHeader(title: "分享我的愿景", showBack: true)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VisionSharePreviewPageVisionSelector(
                        visions: viewModel.visions,
                        selectedVisionId: viewModel.visionId,
                        onSelect: { id in
                            viewModel.selectVision(id: id)
                        }
                    )

                    VisionSharePreviewPageTemplateSelector(
                        templates: viewModel.templates,
                        selectedTemplateId: viewModel.selectedTemplateId,
                        onSelect: { id in
                            viewModel.selectTemplate(id: id)
                        }
                    )

                    VisionSharePreviewPagePreviewSection(
                        vision: viewModel.selectedVision,
                        template: viewModel.selectedTemplate,
                        previewKey: viewModel.previewKey
                    )

                    VisionSharePreviewPageActions(
                        isSaving: viewModel.isSaving,
                        isSharing: viewModel.isSharing,
                        isClientReady: viewModel.isClientReady,
                        isShareMenuVisible: viewModel.isShareMenuVisible,
                        onSaveImage: { viewModel.saveImage() },
                        onSetWallpaper: { viewModel.setWallpaper() },
                        onToggleShareMenu: { viewModel.toggleShareMenu() },
                        onSharePlatform: { platform in viewModel.share(to: platform) },
                        onCloseShareMenu: { viewModel.hideShareMenu() }
                    )

                    VisionSharePreviewPageTipCard()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                .frame(maxWidth: 402)
                .frame(maxWidth: .infinity)
            }
        }
        .background(AppTheme.colors.background.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            VisionSharePreviewPageToastHost(
                toast: viewModel.toast,
                onDismiss: { viewModel.dismissToast() }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .onAppear { viewModel.onAppear() }
        .onTapGesture { viewModel.hideShareMenu() }
        .navigationBarBackButtonHidden(true)
    }
}

private struct VisionSharePreviewPageVisionSelector: View {
    let visions: [VisionItemData]
    let selectedVisionId: String
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择愿景")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.colors.onMuted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(visions) { vision in
                        VisionSharePreviewPageVisionChip(
                            title: vision.title,
                            isSelected: vision.id == selectedVisionId,
                            onTap: { onSelect(vision.id) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, -16)
        }
    }
}

private struct VisionSharePreviewPageVisionChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? AppTheme.colors.onPrimary : AppTheme.colors.onMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.colors.primary : AppTheme.colors.muted)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}

private struct VisionSharePreviewPageTemplateSelector: View {
    let templates: [VisionSharePreviewViewModel.VisionSharePreviewPageTemplate]
    let selectedTemplateId: String
    let onSelect: (String) -> Void

    private let grid = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择模板")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.colors.onMuted)

            LazyVGrid(columns: grid, spacing: 12) {
                ForEach(templates) { template in
                    VisionSharePreviewPageTemplateTile(
                        template: template,
                        isSelected: template.id == selectedTemplateId,
                        onTap: { onSelect(template.id) }
                    )
                }
            }
        }
    }
}

private struct VisionSharePreviewPageTemplateTile: View {
    let template: VisionSharePreviewViewModel.VisionSharePreviewPageTemplate
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(isSelected ? AppTheme.colors.primary : AppTheme.colors.muted)
                        Text(firstCharacter)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isSelected ? AppTheme.colors.onPrimary : AppTheme.colors.onMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(width: 32, height: 32)

                    Spacer(minLength: 8)
                }
                .padding(.bottom, 8)

                Text(template.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.colors.onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(template.description)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.colors.onMuted)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? AppTheme.colors.primary.opacity(0.10) : AppTheme.colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? AppTheme.colors.primary : AppTheme.colors.border, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(template.name))
    }

    private var firstCharacter: String {
        let trimmed = template.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = trimmed.first {
            return String(first)
        }
        return "T"
    }
}

private struct VisionSharePreviewPagePreviewSection: View {
    let vision: VisionItemData
    let template: VisionSharePreviewViewModel.VisionSharePreviewPageTemplate
    let previewKey: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("预览效果")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.colors.onMuted)

            VStack(spacing: 0) {
                VisionSharePreviewPagePreviewCard(
                    visionTitle: vision.title,
                    visionDescription: vision.description,
                    imageUrl: vision.imageUrl,
                    style: template.style,
                    previewKey: previewKey
                )
                .frame(maxWidth: 320)
            }
            .frame(maxWidth: .infinity, minHeight: 384, alignment: .center)
            .padding(16)
            .background(AppTheme.colors.muted.opacity(0.50))
            .cornerRadius(12)
            .clipped()
        }
    }
}

private struct VisionSharePreviewPagePreviewCard: View {
    let visionTitle: String
    let visionDescription: String
    let imageUrl: String
    let style: VisionSharePreviewViewModel.VisionSharePreviewPageTemplate.Style
    let previewKey: String

    var body: some View {
        ZStack {
            backgroundView

            contentView
        }
        .aspectRatio(9.0 / 16.0, contentMode: .fit)
        .cornerRadius(12)
        .shadow(color: AppTheme.shadow.card.color, radius: AppTheme.shadow.card.radius, x: 0, y: 4)
        .id(previewKey)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("愿景分享预览"))
    }

    private var backgroundView: some View {
        Group {
            switch style {
            case VisionSharePreviewViewModel.VisionSharePreviewPageTemplate.Style.minimal:
                AppTheme.colors.surface

            case VisionSharePreviewViewModel.VisionSharePreviewPageTemplate.Style.gradient:
                LinearGradient(
                    colors: [
                        AppTheme.colors.primary.opacity(0.20),
                        AppTheme.colors.secondary.opacity(0.20),
                        AppTheme.colors.accent.opacity(0.20)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

            case VisionSharePreviewViewModel.VisionSharePreviewPageTemplate.Style.artistic:
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.92, blue: 0.98),
                        Color(red: 0.98, green: 0.92, blue: 0.95),
                        Color(red: 0.99, green: 0.94, blue: 0.90)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

case VisionSharePreviewViewModel.VisionSharePreviewPageTemplate.Style.motivational:
                LinearGradient(
                    colors: [
                        Color(red: 0.93, green: 0.97, blue: 1.00),
                        Color(red: 0.93, green: 0.94, blue: 1.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch style {
        case VisionSharePreviewViewModel.VisionSharePreviewPageTemplate.Style.minimal:
            VisionSharePreviewPagePreviewMinimal(
                visionTitle: visionTitle,
                visionDescription: visionDescription,
                imageUrl: imageUrl
            )

        case VisionSharePreviewViewModel.VisionSharePreviewPageTemplate.Style.gradient:
            VisionSharePreviewPagePreviewGradient(
                visionTitle: visionTitle,
                visionDescription: visionDescription,
                imageUrl: imageUrl
            )

        case VisionSharePreviewViewModel.VisionSharePreviewPageTemplate.Style.artistic:
            VisionSharePreviewPagePreviewArtistic(
                visionTitle: visionTitle,
                visionDescription: visionDescription,
                imageUrl: imageUrl
            )

        case VisionSharePreviewViewModel.VisionSharePreviewPageTemplate.Style.motivational:
            VisionSharePreviewPagePreviewMotivational(
                visionTitle: visionTitle,
                visionDescription: visionDescription,
                imageUrl: imageUrl
            )
        }
    }
}

private struct VisionSharePreviewPagePreviewMinimal: View {
    let visionTitle: String
    let visionDescription: String
    let imageUrl: String

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                VisionImage.fixed(urlOrAsset: imageUrl, width: 128, height: 128)
                    .contentMode(RemoteImageContentMode.fill)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 2)

                VStack(spacing: 8) {
                    Text(visionTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.colors.onSurface)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(visionDescription)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.colors.onMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .frame(maxWidth: 220)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)

            Divider()
                .overlay(AppTheme.colors.border.opacity(0.30))

            Text("来自 GlowMoment · 我的成长之旅")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.colors.onMuted)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct VisionSharePreviewPagePreviewGradient: View {
    let visionTitle: String
    let visionDescription: String
    let imageUrl: String

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                VisionImage.fixed(urlOrAsset: imageUrl, width: 160, height: 160)
                    .contentMode(RemoteImageContentMode.fill)
                    .cornerRadius(80)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.50), lineWidth: 4)
                    )
                    .shadow(color: AppTheme.shadow.card.color, radius: AppTheme.shadow.card.radius, x: 0, y: 4)

                VStack(spacing: 12) {
                    VisionSharePreviewPageGradientTitle(text: visionTitle)

                    Text(visionDescription)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.colors.onSurface)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .frame(maxWidth: 220)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)

            Text("✨ 我的愿景 · GlowMoment ✨")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.colors.primary)
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct VisionSharePreviewPageGradientTitle: View {
    let text: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.colors.primary, Color(red: 1.00, green: 0.55, blue: 0.40)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .mask(
                Text(text)
                    .font(.system(size: 30, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            )
        }
        .frame(maxWidth: .infinity)
    }
}

private struct VisionSharePreviewPagePreviewArtistic: View {
    let visionTitle: String
    let visionDescription: String
    let imageUrl: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("我的愿景")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.colors.chart5)
                    .cornerRadius(999)

                Text(visionTitle)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.colors.onSurface)
                    .lineLimit(2)
            }

            Spacer(minLength: 12)

            HStack(spacing: 0) {
                Spacer(minLength: 0)
                VisionImage.fixed(urlOrAsset: imageUrl, width: 128, height: 128)
                    .contentMode(RemoteImageContentMode.fill)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 2)
                    .rotationEffect(.degrees(-3))
                Spacer(minLength: 0)
            }

            Spacer(minLength: 12)

            VStack(alignment: .leading, spacing: 8) {
                Text(visionDescription)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.colors.onSurface)
                    .lineSpacing(2)
                    .lineLimit(4)

                Text("GlowMoment · 成长的每一刻都闪闪发光")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.colors.onMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(24)
    }
}

private struct VisionSharePreviewPagePreviewMotivational: View {
    let visionTitle: String
    let visionDescription: String
    let imageUrl: String

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 24) {
                VisionSharePreviewPageGradientTitle(text: "🌟")

                VStack(spacing: 16) {
                    Text(visionTitle)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(AppTheme.colors.onSurface)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(visionDescription)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.colors.onSurface)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .frame(maxWidth: 220)
                        .lineLimit(4)
                }

                VisionImage.fixed(urlOrAsset: imageUrl, width: 96, height: 96)
                    .contentMode(RemoteImageContentMode.fill)
                    .cornerRadius(48)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.50), lineWidth: 4)
                    )
                    .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)

            VStack(spacing: 8) {
                Text("我正在成为更好的自己")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.colors.onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("GlowMoment · 每一刻都是成长的机会")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.colors.onMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct VisionSharePreviewPageActions: View {
    let isSaving: Bool
    let isSharing: Bool
    let isClientReady: Bool
    let isShareMenuVisible: Bool

    let onSaveImage: () -> Void
    let onSetWallpaper: () -> Void
    let onToggleShareMenu: () -> Void
    let onSharePlatform: (VisionSharePreviewViewModel.VisionSharePreviewPageSharePlatform) -> Void
    let onCloseShareMenu: () -> Void

    private let grid = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: grid, spacing: 12) {
                VisionSharePreviewPageOutlineActionButton(
                    icon: "Download",
                    title: isSaving ? "保存中" : "保存图片",
                    isEnabled: isClientReady && !isSaving,
                    isLoading: isSaving,
                    loadingDotColor: AppTheme.colors.primary,
                    onTap: onSaveImage
                )

                VisionSharePreviewPageOutlineActionButton(
                    icon: "Image",
                    title: isSaving ? "设置中" : "设置屏保",
                    isEnabled: isClientReady && !isSaving,
                    isLoading: isSaving,
                    loadingDotColor: AppTheme.colors.primary,
                    onTap: onSetWallpaper
                )
            }

            ZStack(alignment: .top) {
                VisionSharePreviewPagePrimaryButton(
                    icon: "Share2",
                    title: isSharing ? "分享中" : "分享到社交平台",
                    isEnabled: isClientReady && !isSharing,
                    isLoading: isSharing,
                    onTap: onToggleShareMenu
                )
                .padding(.top, 0)

                if isShareMenuVisible {
                    VisionSharePreviewPageShareMenu(
                        onSharePlatform: onSharePlatform,
                        onClose: onCloseShareMenu
                    )
                    .padding(.top, 52)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isShareMenuVisible)

            VisionSharePreviewPageHintCard(
                backgroundColor: AppTheme.colors.accent.opacity(0.10),
                borderColor: AppTheme.colors.accent.opacity(0.30),
                iconName: "Info",
                iconColor: AppTheme.colors.accent,
                text: "分享您的愿景卡片，邀请朋友见证您的成长之旅。每一次分享都是对梦想的坚定承诺。"
            )
        }
    }
}

private struct VisionSharePreviewPageOutlineActionButton: View {
    let icon: String
    let title: String
    let isEnabled: Bool
    let isLoading: Bool
    let loadingDotColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                SafeIcon(icon, size: 18, color: AppTheme.colors.onSurface)

                if isLoading {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(loadingDotColor)
                            .frame(width: 12, height: 12)
                            .opacity(0.9)
                            .scaleEffect(0.95)
                        Text(title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.colors.onSurface)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                } else {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.colors.onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(height: 36)
            .frame(maxWidth: .infinity)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(AppTheme.colors.border.opacity(0.9), lineWidth: 1)
            )
            .cornerRadius(6)
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(Text(title))
    }
}

private struct VisionSharePreviewPagePrimaryButton: View {
    let icon: String
    let title: String
    let isEnabled: Bool
    let isLoading: Bool
    let onTap: () -> Void

    var body: some View {
        AppButton(action: onTap) {
            SafeIcon(icon, size: 18, color: AppTheme.colors.onPrimary)

            if isLoading {
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.colors.onPrimary)
                        .frame(width: 12, height: 12)
                        .opacity(0.85)
                    Text(title)
                        .foregroundColor(AppTheme.colors.onPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            } else {
                Text(title)
                    .foregroundColor(AppTheme.colors.onPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .backgroundColor(AppTheme.colors.primary)
        .foregroundColor(AppTheme.colors.onPrimary)
        .cornerRadius(6)
        .disabled(!isEnabled)
        .fullWidth()
        .accessibilityLabel(Text(title))
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

private struct VisionSharePreviewPageShareMenu: View {
    let onSharePlatform: (VisionSharePreviewViewModel.VisionSharePreviewPageSharePlatform) -> Void
    let onClose: () -> Void

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("选择分享平台")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.colors.onMuted)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                Divider()
                    .overlay(AppTheme.colors.border)

                VisionSharePreviewPageShareMenuRow(
                    icon: "MessageCircle",
                    title: "微信",
                    onTap: { onSharePlatform(VisionSharePreviewViewModel.VisionSharePreviewPageSharePlatform.wechat) }
                )

                VisionSharePreviewPageShareMenuRow(
                    icon: "MessageSquare",
                    title: "QQ",
                    onTap: { onSharePlatform(VisionSharePreviewViewModel.VisionSharePreviewPageSharePlatform.qq) }
                )

                VisionSharePreviewPageShareMenuRow(
                    icon: "Share2",
                    title: "微博",
                    onTap: { onSharePlatform(VisionSharePreviewViewModel.VisionSharePreviewPageSharePlatform.weibo) }
                )
            }
            .padding(.bottom, 8)
        }
        .background(AppTheme.colors.surface)
        .borderColor(AppTheme.colors.border)
        .cornerRadius(12)
        .shadow(color: AppTheme.shadow.soft.color, radius: AppTheme.shadow.soft.radius)
        .frame(width: 192, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onTapGesture { }
    }
}

private struct VisionSharePreviewPageShareMenuRow: View {
    let icon: String
    let title: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                SafeIcon(icon, size: 16, color: AppTheme.colors.onSurface)
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.colors.onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}

private struct VisionSharePreviewPageHintCard: View {
    let backgroundColor: Color
    let borderColor: Color
    let iconName: String
    let iconColor: Color
    let text: String

    var body: some View {
        AppCard {
            HStack(alignment: .top, spacing: 8) {
                SafeIcon(iconName, size: 14, color: iconColor)
                    .padding(.top, 2)

                Text(text)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.colors.onMuted)
                    .lineSpacing(2)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background(backgroundColor)
        .borderColor(borderColor)
        .cornerRadius(12)
        .shadow(color: Color.clear, radius: 0)
    }
}

private struct VisionSharePreviewPageTipCard: View {
    var body: some View {
        AppCard {
            HStack(alignment: .top, spacing: 8) {
                SafeIcon("Lightbulb", size: 16, color: AppTheme.colors.primary)
                    .padding(.top, 2)

                Text("分享您的愿景，让更多人见证您的成长之旅。每一次分享都是对自己的承诺。")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.colors.onMuted)
                    .lineSpacing(2)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
        .background(AppTheme.colors.secondary.opacity(0.20))
        .borderColor(AppTheme.colors.secondary.opacity(0.30))
        .cornerRadius(12)
        .shadow(color: Color.clear, radius: 0)
    }
}

private struct VisionSharePreviewPageToastHost: View {
    let toast: VisionSharePreviewViewModel.VisionSharePreviewPageToast?
    let onDismiss: () -> Void

    var body: some View {
        if let toast {
            VisionSharePreviewPageToastView(
                kind: toast.kind,
                title: toast.title,
                message: toast.message,
                onDismiss: onDismiss
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.2), value: toast.id)
        }
    }
}

private struct VisionSharePreviewPageToastView: View {
    let kind: VisionSharePreviewViewModel.VisionSharePreviewPageToast.Kind
    let title: String
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        Button(action: onDismiss) {
            HStack(alignment: .top, spacing: 12) {
                SafeIcon(iconName, size: 18, color: iconColor)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.colors.onSurface)
                        .lineLimit(2)

                    Text(message)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.colors.onMuted)
                        .lineLimit(3)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(AppTheme.colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(AppTheme.colors.border.opacity(0.8), lineWidth: 1)
            )
            .cornerRadius(12)
            .shadow(color: AppTheme.shadow.card.color, radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }

    private var iconName: String {
        switch kind {
        case VisionSharePreviewViewModel.VisionSharePreviewPageToast.Kind.success:
            return "CheckCircle"
        case VisionSharePreviewViewModel.VisionSharePreviewPageToast.Kind.error:
            return "XCircle"
        }
    }

    private var iconColor: Color {
        switch kind {
        case VisionSharePreviewViewModel.VisionSharePreviewPageToast.Kind.success:
            return Color(red: 0.10, green: 0.65, blue: 0.30)
        case VisionSharePreviewViewModel.VisionSharePreviewPageToast.Kind.error:
            return AppTheme.colors.error
        }
    }
}