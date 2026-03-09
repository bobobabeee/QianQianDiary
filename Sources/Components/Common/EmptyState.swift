import SwiftUI
import Foundation

struct EmptyState: View {
    enum Illustration {
        case qianqian
        case donut
        case custom
        /// 日历空状态专用：期待表情小狗（本地资源 calendar_empty_puppy）
        case calendarEmpty
    }

    @EnvironmentObject private var router: AppRouter

    var illustration: Illustration = Illustration.qianqian
    var customImageUrl: String? = nil
    let title: String
    let message: String
    var actionText: String? = nil
    var actionDestination: AppRouter.Destination? = nil
    var onAction: (() -> Void)? = nil

    private let donutImageUrl = "https://spark-builder.s3.cn-north-1.amazonaws.com.cn/image/2026/3/4/ae2ae759-2d82-45fb-8d3b-e9e7f56539cf.png"

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                IllustrationView(
                    illustration: illustration,
                    donutImageUrl: donutImageUrl,
                    customImageUrl: customImageUrl
                )
                .padding(.bottom, illustration == .calendarEmpty ? 16 : 24)

                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.colors.onSurface)
                    .padding(.bottom, 8)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.colors.onMuted)
                    .lineSpacing(2)
                    .frame(maxWidth: 384)
                    .padding(.bottom, 24)

                if let actionText, !actionText.isEmpty {
                    AppButton(actionText, action: handleAction)
                        .backgroundColor(AppTheme.colors.primary)
                        .foregroundColor(AppTheme.colors.onPrimary)
                        .cornerRadius(AppTheme.radius.small)
                        .contentPadding(horizontal: 24, vertical: 10)
                        .height(40)
                        .accessibilityLabel(Text(actionText))
                        .frame(minWidth: 140)
                }
            }
            .padding(.vertical, 48)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
    }

    private func handleAction() {
        if let actionDestination {
            router.navigate(to: actionDestination, style: AppRouter.NavigationStyle.push)
            return
        }
        onAction?()
    }
}

private struct IllustrationView: View {
    let illustration: EmptyState.Illustration
    let donutImageUrl: String
    let customImageUrl: String?

    var body: some View {
        Group {
            switch illustration {
            case EmptyState.Illustration.qianqian:
                QianqianAvatar(expression: QianqianAvatar.Expression.thoughtful, showDialog: false, dialogText: nil, size: QianqianAvatar.SizeVariant.xl)

            case EmptyState.Illustration.donut:
                RemoteImage.fixed(url: donutImageUrl, width: 128, height: 128)
                    .contentMode(RemoteImageContentMode.fit)
                    .opacity(0.80)
                    .accessibilityLabel(Text("暂无内容"))

            case EmptyState.Illustration.custom:
                if let customImageUrl, !customImageUrl.isEmpty {
                    RemoteImage.fixed(url: customImageUrl, width: 128, height: 128)
                        .contentMode(RemoteImageContentMode.fit)
                        .opacity(0.80)
                        .accessibilityLabel(Text("暂无内容"))
                } else {
                    RemoteImage.fixed(url: donutImageUrl, width: 128, height: 128)
                        .contentMode(RemoteImageContentMode.fit)
                        .opacity(0.80)
                        .accessibilityLabel(Text("暂无内容"))
                }

            case EmptyState.Illustration.calendarEmpty:
                VStack(spacing: 12) {
                    Image("calendar_empty_puppy")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 280, maxHeight: 240)
                        .accessibilityLabel(Text("期待记录"))

                    Text("「在一切进展非常顺利的情况下，你也应该继续记录这些成功的事情。」")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.colors.onSurface)
                        .lineSpacing(3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppTheme.colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radius.standard, style: .continuous)
                                .stroke(AppTheme.colors.border.opacity(0.8), lineWidth: 1)
                        )
                        .cornerRadius(AppTheme.radius.standard)
                        .frame(maxWidth: 320)
                }
            }
        }
        .frame(minHeight: 128)
    }
}