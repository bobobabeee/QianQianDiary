import SwiftUI

struct MobileHeader: View {
    @EnvironmentObject private var router: AppRouter

    let title: String
    var showBack: Bool = true
    var actionIcon: String? = nil
    var actionLabel: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                LeftSlot(showBack: showBack, onBack: { router.dismiss() })
                    .frame(width: 40)

                TitleSlot(title: title)
                    .frame(maxWidth: .infinity)

                RightSlot(actionIcon: actionIcon, actionLabel: actionLabel, onAction: onAction)
                    .frame(width: 40)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)

            Rectangle()
                .fill(AppTheme.colors.border.opacity(0.6))
                .frame(height: 1)
        }
        .background(AppTheme.colors.background, ignoresSafeAreaEdges: .top)
    }
}

private struct LeftSlot: View {
    let showBack: Bool
    let onBack: () -> Void

    var body: some View {
        HStack {
            if showBack {
                AppButton(action: onBack) {
                    SafeIcon("ChevronLeft", size: 20, color: AppTheme.colors.onSurface)
                }
                .variant(ButtonVariant.ghost)
                .size(ButtonSize.icon)
                .height(36)
                .cornerRadius(8)
                .accessibilityLabel(Text("返回"))
            } else {
                Color.clear.frame(width: 36, height: 36)
            }
        }
    }
}

private struct TitleSlot: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(AppTheme.colors.onSurface)
            .lineLimit(1)
            .truncationMode(.tail)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 8)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
    }
}

private struct RightSlot: View {
    let actionIcon: String?
    let actionLabel: String?
    let onAction: (() -> Void)?

    var body: some View {
        HStack {
            if let actionIcon, let onAction {
                AppButton(action: onAction) {
                    SafeIcon(actionIcon, size: 20, color: AppTheme.colors.onSurface)
                }
                .variant(ButtonVariant.ghost)
                .size(ButtonSize.icon)
                .height(36)
                .cornerRadius(8)
                .accessibilityLabel(Text(actionLabel ?? "操作"))
            } else {
                Color.clear.frame(width: 36, height: 36)
            }
        }
    }
}