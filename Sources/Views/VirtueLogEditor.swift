import SwiftUI

struct VirtueLogEditor: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = VirtueLogEditorViewModel()

    var body: some View {
        VStack(spacing: 0) {
            MobileHeader(title: "美德践行记录", showBack: true)

            ScrollView {
                VirtueLogEditorContent(
                    virtue: viewModel.virtueCardVirtue,
                    isCompleted: viewModel.isCompleted,
                    reflection: viewModel.reflection,
                    reflectionCountText: viewModel.reflectionCountText,
                    statusHintText: viewModel.statusHintText,
                    statusHintIconName: viewModel.statusHintIconName,
                    statusHintBackground: viewModel.statusHintBackground,
                    statusHintForeground: viewModel.statusHintForeground,
                    onToggleCompleted: { viewModel.toggleCompleted() },
                    onSetCompleted: { viewModel.setCompleted($0) },
                    onReflectionChanged: { viewModel.reflection = $0 },
                    onCancel: handleCancel,
                    onSave: handleSave
                )
            }
            .background(AppTheme.colors.background)
        }
        .background(AppTheme.colors.background)
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.reflection) { _ in
            viewModel.enforceReflectionLimit()
        }
    }

    private func handleCancel() {
        if router.path.isEmpty {
            router.navigate(to: AppRouter.Destination.home, style: AppRouter.NavigationStyle.root)
        } else {
            router.dismiss()
        }
    }

    private func handleSave() {
        viewModel.save()
        router.navigate(to: AppRouter.Destination.virtueGrowthStats, style: AppRouter.NavigationStyle.push)
    }
}

private struct VirtueLogEditorContent: View {
    let virtue: VirtueCard.Virtue
    let isCompleted: Bool
    let reflection: String
    let reflectionCountText: String

    let statusHintText: String
    let statusHintIconName: String
    let statusHintBackground: Color
    let statusHintForeground: Color

    let onToggleCompleted: () -> Void
    let onSetCompleted: (Bool) -> Void
    let onReflectionChanged: (String) -> Void
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VirtueCard(virtue: virtue, isExpanded: false)

            VirtueLogEditorPracticeStatusCard(
                isCompleted: isCompleted,
                statusHintText: statusHintText,
                statusHintIconName: statusHintIconName,
                statusHintBackground: statusHintBackground,
                statusHintForeground: statusHintForeground,
                onToggleCompleted: onToggleCompleted,
                onSetCompleted: onSetCompleted
            )

            VirtueLogEditorReflectionCard(
                reflection: reflection,
                reflectionCountText: reflectionCountText,
                onReflectionChanged: onReflectionChanged
            )

            VirtueLogEditorActionButtons(onCancel: onCancel, onSave: onSave)

            Color.clear.frame(height: 16)
        }
        .padding(.horizontal, AppTheme.spacing.screenHorizontal)
        .padding(.vertical, AppTheme.spacing.lg)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity)
    }
}

private struct VirtueLogEditorPracticeStatusCard: View {
    let isCompleted: Bool
    let statusHintText: String
    let statusHintIconName: String
    let statusHintBackground: Color
    let statusHintForeground: Color
    let onToggleCompleted: () -> Void
    let onSetCompleted: (Bool) -> Void

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 0) {
                AppCardHeader {
                    AppCardTitle("今日践行状态")
                        .font(size: 18, weight: .semibold)
                        .textColor(AppTheme.colors.onSurface)
                }
                .padding(24)
                .spacing(6)

                AppCardContent {
                    VirtueLogEditorStatusRow(isCompleted: isCompleted, onToggle: onToggleCompleted, onSet: onSetCompleted)

                    VirtueLogEditorStatusHint(
                        text: statusHintText,
                        iconName: statusHintIconName,
                        backgroundColor: statusHintBackground,
                        foregroundColor: statusHintForeground
                    )
                }
                .padding(top: 0, horizontal: 24, bottom: 24)
                .spacing(16)
            }
        }
        .background(AppTheme.colors.surface)
        .borderColor(AppTheme.colors.border)
        .cornerRadius(AppTheme.radius.standard)
        .shadow(color: AppTheme.shadow.soft.color, radius: AppTheme.shadow.soft.radius)
    }
}

private struct VirtueLogEditorStatusRow: View {
    let isCompleted: Bool
    let onToggle: () -> Void
    let onSet: (Bool) -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                AppCheckbox(isChecked: Binding(get: { isCompleted }, set: { onSet($0) }))
                    .size(20)
                    .primaryColor(AppTheme.colors.primary)
                    .checkColor(AppTheme.colors.onPrimary)

                Text("我已在今天践行了这项美德")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.colors.onSurface)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
            }
            .padding(12)
            .background(AppTheme.colors.muted.opacity(0.5))
            .cornerRadius(AppTheme.radius.standard)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("我已在今天践行了这项美德"))
        .accessibilityValue(Text(isCompleted ? "已勾选" : "未勾选"))
    }
}

private struct VirtueLogEditorStatusHint: View {
    let text: String
    let iconName: String
    let backgroundColor: Color
    let foregroundColor: Color

    var body: some View {
        HStack(spacing: 8) {
            SafeIcon(iconName, size: 16, color: foregroundColor)
                .accessibilityHidden(true)

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(foregroundColor)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
        }
        .padding(8)
        .background(backgroundColor)
        .cornerRadius(AppTheme.radius.standard)
    }
}

private struct VirtueLogEditorReflectionCard: View {
    let reflection: String
    let reflectionCountText: String
    let onReflectionChanged: (String) -> Void

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 0) {
                AppCardHeader {
                    VStack(alignment: .leading, spacing: 6) {
                        AppCardTitle("践行心得")
                            .font(size: 18, weight: .semibold)
                            .textColor(AppTheme.colors.onSurface)

                        Text("记录你今天如何践行这项美德,可以是具体的行动或内心的感受")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.colors.onMuted)
                            .lineSpacing(2)
                            .padding(.top, 4)
                    }
                }
                .padding(24)

                AppCardContent {
                    AppTextarea(
                        text: Binding(get: { reflection }, set: { onReflectionChanged($0) }),
                        placeholder: "例如:今天在地铁上给老奶奶让座了,微笑着祝她有美好的一天,心情很好。"
                    )
                    .minHeight(120)
                    .fontSize(16)
                    .borderColor(AppTheme.colors.border)
                    .focusRingColor(AppTheme.colors.primary)
                    .cornerRadius(AppTheme.radius.small)
                    .textColor(AppTheme.colors.onSurface)

                    Text(reflectionCountText)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.colors.onMuted)
                        .padding(.top, 8)
                }
                .padding(top: 0, horizontal: 24, bottom: 24)
                .spacing(0)
            }
        }
        .background(AppTheme.colors.surface)
        .borderColor(AppTheme.colors.border)
        .cornerRadius(AppTheme.radius.standard)
        .shadow(color: AppTheme.shadow.soft.color, radius: AppTheme.shadow.soft.radius)
    }
}

private struct VirtueLogEditorActionButtons: View {
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AppButton("取消", action: onCancel)
                .variant(ButtonVariant.outline)
                .cornerRadius(AppTheme.radius.small)
                .height(40)
                .frame(maxWidth: .infinity)

            AppButton(action: onSave) {
                SafeIcon("Save", size: 18, color: AppTheme.colors.onPrimary)
                Text("保存并查看统计")
            }
            .backgroundColor(AppTheme.colors.primary)
            .foregroundColor(AppTheme.colors.onPrimary)
            .cornerRadius(AppTheme.radius.small)
            .height(40)
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 16)
    }
}