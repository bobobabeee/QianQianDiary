import SwiftUI

struct VisionBoardMain: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = VisionBoardMainViewModel()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                MobileHeader(
                    title: "我的愿景板",
                    showBack: false,
                    actionIcon: "Plus",
                    actionLabel: "添加愿景",
                    onAction: handleAddVision
                )

                ScrollView {
                    VisionBoardMainContent(
                        viewModel: viewModel,
                        onAddVision: handleAddVision,
                        onEditVision: handleEditVision(visionId:),
                        onShareVision: handleShareVision(visionId:),
                        onRequestDelete: viewModel.requestDelete(visionId:)
                    )
                }
                .background(AppTheme.colors.background)
            }
            .safeAreaInset(edge: .bottom) {
                MobileBottomNav(activeDestination: AppRouter.Destination.visionBoardMain)
            }

            VisionBoardMainFloatingAddButton(onTap: handleAddVision)
                .padding(.trailing, 16)
                .padding(.bottom, 96)
        }
        .background(AppTheme.colors.background.ignoresSafeArea())
        .confirmationDialog(
            "确定要删除这个愿景吗？",
            isPresented: deleteDialogPresentedBinding,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) { viewModel.confirmDelete() }
            Button("取消", role: .cancel) { viewModel.cancelDelete() }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var deleteDialogPresentedBinding: Binding<Bool> {
        Binding(
            get: { viewModel.pendingDeleteVisionId != nil },
            set: { newValue in
                if !newValue {
                    viewModel.cancelDelete()
                }
            }
        )
    }

    private func handleAddVision() {
        router.navigate(to: AppRouter.Destination.visionBoardEditor(id: nil), style: AppRouter.NavigationStyle.push)
    }

    private func handleEditVision(visionId: String) {
        router.navigate(to: AppRouter.Destination.visionBoardEditor(id: visionId), style: AppRouter.NavigationStyle.push)
    }

    private func handleShareVision(visionId: String) {
        if visionId.isEmpty { return }
        router.navigate(to: AppRouter.Destination.visionSharePreview(id: visionId), style: AppRouter.NavigationStyle.push)
    }
}

private struct VisionBoardMainContent: View {
    @ObservedObject var viewModel: VisionBoardMainViewModel
    let onAddVision: () -> Void
    let onEditVision: (String) -> Void
    let onShareVision: (String) -> Void
    let onRequestDelete: (String) -> Void

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16, alignment: .top),
        GridItem(.flexible(), spacing: 16, alignment: .top)
    ]

    var body: some View {
        VStack(spacing: 24) {
            VisionBoardMainCategoryTabs(
                filters: viewModel.categoryFilters,
                selected: viewModel.selectedFilter,
                labelFor: viewModel.label(for:),
                onSelect: viewModel.selectFilter(_:)
            )

            if viewModel.filteredVisions.isEmpty {
                EmptyState(
                    illustration: EmptyState.Illustration.donut,
                    customImageUrl: nil,
                    title: "还没有愿景呢",
                    message: "点击下方按钮添加你的第一个愿景目标,让梦想可视化!",
                    actionText: "添加愿景",
                    actionDestination: AppRouter.Destination.visionBoardEditor(id: nil),
                    onAction: nil
                )
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.filteredVisions, id: \.id) { vision in
                        VisionBoardMainVisionCard(
                            vision: vision,
                            categoryLabel: viewModel.label(for: vision.category),
                            onTap: { onEditVision(vision.id) },
                            onShare: { onShareVision(vision.id) },
                            onEdit: { onEditVision(vision.id) },
                            onDelete: { onRequestDelete(vision.id) }
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.spacing.screenHorizontal)
        .padding(.vertical, AppTheme.spacing.lg)
        .frame(maxWidth: 384)
        .frame(maxWidth: .infinity)
    }
}

private struct VisionBoardMainCategoryTabs: View {
    let filters: [VisionBoardMainViewModel.VisionBoardMainCategoryFilter]
    let selected: VisionBoardMainViewModel.VisionBoardMainCategoryFilter
    let labelFor: (VisionBoardMainViewModel.VisionBoardMainCategoryFilter) -> String
    let onSelect: (VisionBoardMainViewModel.VisionBoardMainCategoryFilter) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.id) { filter in
                    let isSelected = (filter == selected)
                    VisionBoardMainCategoryPill(
                        title: labelFor(filter),
                        isSelected: isSelected,
                        onTap: { onSelect(filter) }
                    )
                }
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct VisionBoardMainCategoryPill: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        AppButton(title, action: onTap)
            .size(ButtonSize.small)
            .backgroundColor(isSelected ? AppTheme.colors.primary : Color.clear)
            .foregroundColor(isSelected ? AppTheme.colors.onPrimary : AppTheme.colors.onSurface)
            .cornerRadius(999)
            .background(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .stroke(AppTheme.colors.border, lineWidth: isSelected ? 0 : 1)
            )
            .accessibilityLabel(Text(title))
    }
}

private struct VisionBoardMainVisionCard: View {
    let vision: VisionItemData
    let categoryLabel: String
    let onTap: () -> Void
    let onShare: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 0) {
                VisionBoardMainVisionImageArea(
                    imageUrl: vision.imageUrl,
                    title: vision.title,
                    categoryLabel: categoryLabel,
                    onShare: onShare,
                    onMore: onEdit
                )

                VisionBoardMainVisionContent(
                    title: vision.title,
                    description: vision.description,
                    targetDate: vision.targetDate
                )
            }
        }
        .background(AppTheme.colors.surface)
        .borderColor(AppTheme.colors.border)
        .cornerRadius(AppTheme.radius.standard)
        .shadow(color: AppTheme.shadow.soft.color, radius: AppTheme.shadow.soft.radius)
        .contentShape(RoundedRectangle(cornerRadius: AppTheme.radius.standard, style: .continuous))
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button("编辑") { onEdit() }
            Button("删除", role: .destructive) { onDelete() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(vision.title))
    }
}

private struct VisionBoardMainVisionImageArea: View {
    let imageUrl: String
    let title: String
    let categoryLabel: String
    let onShare: () -> Void
    let onMore: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            VisionImage.background(urlOrAsset: imageUrl)
                .contentMode(RemoteImageContentMode.fill)
                .placeholder(AppTheme.colors.muted)

            HStack(spacing: 0) {
                VisionBoardMainCategoryBadge(text: categoryLabel)

                Spacer(minLength: 8)

                HStack(spacing: 8) {
                    VisionBoardMainIconCircleButton(
                        icon: "Share2",
                        accessibilityLabel: "分享",
                        onTap: onShare
                    )

                    VisionBoardMainIconCircleButton(
                        icon: "MoreVertical",
                        accessibilityLabel: "更多操作",
                        onTap: onMore
                    )
                }
            }
            .padding(8)
        }
        .frame(height: 160)
        .background(AppTheme.colors.muted)
        .clipped()
        .accessibilityHidden(true)
    }
}

private struct VisionBoardMainCategoryBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(AppTheme.colors.onPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppTheme.colors.primary.opacity(0.90))
            .clipShape(Capsule())
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

private struct VisionBoardMainIconCircleButton: View {
    let icon: String
    let accessibilityLabel: String
    let onTap: () -> Void

    var body: some View {
        AppButton(action: onTap) {
            SafeIcon(icon, size: 16, color: AppTheme.colors.onSurface)
        }
        .variant(ButtonVariant.secondary)
        .size(ButtonSize.icon)
        .height(32)
        .cornerRadius(16)
        .backgroundColor(AppTheme.colors.secondary)
        .foregroundColor(AppTheme.colors.onSecondary)
        .accessibilityLabel(Text(accessibilityLabel))
    }
}

private struct VisionBoardMainVisionContent: View {
    let title: String
    let description: String
    let targetDate: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.colors.onSurface)
                .lineLimit(2)
                .padding(.bottom, 4)

            Text(description)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.colors.onMuted)
                .lineLimit(2)

            if !targetDate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(spacing: 0) {
                    Divider()
                        .overlay(AppTheme.colors.border)
                        .padding(.top, 8)

                    HStack(spacing: 4) {
                        SafeIcon("Calendar", size: 12, color: AppTheme.colors.onMuted)
                        Text(targetDate)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.colors.onMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(minWidth: 0, alignment: .leading)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(12)
    }
}

private struct VisionBoardMainFloatingAddButton: View {
    let onTap: () -> Void

    var body: some View {
        AppButton(action: onTap) {
            SafeIcon("Plus", size: 24, color: AppTheme.colors.onPrimary)
        }
        .size(ButtonSize.icon)
        .height(56)
        .cornerRadius(28)
        .backgroundColor(AppTheme.colors.primary)
        .foregroundColor(AppTheme.colors.onPrimary)
        .shadow(color: AppTheme.shadow.card.color, radius: AppTheme.shadow.card.radius, x: 0, y: 4)
        .frame(width: 56, height: 56)
        .accessibilityLabel(Text("添加愿景"))
    }
}