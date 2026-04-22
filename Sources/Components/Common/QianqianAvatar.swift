import SwiftUI
import Foundation

struct QianqianAvatar: View {
    enum Expression {
        case happy
        case speaking
        case thoughtful
    }

    enum SizeVariant {
        case sm
        case md
        case lg
        case xl
    }

    var expression: Expression = Expression.happy
    var showDialog: Bool = false
    var dialogText: String? = nil
    var size: SizeVariant = SizeVariant.md

    /// Poppy 头像（本地资源）。请在 Assets.xcassets 里添加同名图片。
    private let qianqianAssetName = "qianqian_avatar"
    private let qianqianFallbackImageUrl = "https://spark-builder.s3.cn-north-1.amazonaws.com.cn/image/2026/3/4/0630aebe-131b-40ba-a901-93437bf84147.png"

    var body: some View {
        VStack(spacing: 0) {
            AvatarCircle(assetName: qianqianAssetName, fallbackImageUrl: qianqianFallbackImageUrl, size: resolvedSize)

            if showDialog, let dialogText, !dialogText.isEmpty {
                DialogBubble(text: dialogText, arrowUp: true)
                    .padding(.top, 12)
                    .transition(DialogBubbleTransition.transition)
                    .animation(.easeOut(duration: 0.3), value: showDialog)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var resolvedSize: CGFloat {
        switch size {
        case SizeVariant.sm: 64
        case SizeVariant.md: 96
        case SizeVariant.lg: 128
        case SizeVariant.xl: 160
        }
    }
}

private struct AvatarCircle: View {
    let assetName: String
    let fallbackImageUrl: String
    let size: CGFloat

    var body: some View {
        Image(assetName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipped()
            .background(
                // 如果你还没加本地资源（Image 取不到图），这里用网络图兜底显示。
                RemoteImage.fixed(url: fallbackImageUrl, width: size, height: size)
                    .contentMode(RemoteImageContentMode.fill)
                    .opacity(0.0001)
            )
            .cornerRadius(size / 2)
            .background(
                Circle()
                    .fill(AppTheme.colors.primary.opacity(0.10))
            )
            .clipShape(Circle())
            .accessibilityLabel(Text("Poppy"))
    }
}

private struct DialogBubble: View {
    let text: String
    /// true：箭头在气泡上方指向头像；false：箭头在下方（原样式）
    var arrowUp: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            if arrowUp {
                BubbleArrow()
                    .fill(AppTheme.colors.surface)
                    .frame(width: 16, height: 8)
                    .overlay(
                        BubbleArrow()
                            .stroke(AppTheme.colors.border.opacity(0.7), lineWidth: 1)
                    )
                    .rotationEffect(.degrees(180))
                    .offset(y: 1)
            }

            AppCard {
                VStack(alignment: .leading, spacing: 0) {
                    Text(text)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.colors.onSurface)
                        .lineSpacing(2)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .background(Color.clear)
            }
            .background(AppTheme.colors.surface)
            .borderColor(AppTheme.colors.border)
            .cornerRadius(AppTheme.radius.standard)
            .shadow(color: AppTheme.shadow.card.color, radius: AppTheme.shadow.card.radius)

            if !arrowUp {
                BubbleArrow()
                    .fill(AppTheme.colors.surface)
                    .frame(width: 16, height: 8)
                    .overlay(
                        BubbleArrow()
                            .stroke(AppTheme.colors.border.opacity(0.7), lineWidth: 1)
                    )
                    .offset(y: -1)
            }
        }
        .frame(maxWidth: 320)
    }
}

private struct BubbleArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

private enum DialogBubbleTransition {
    static let transition: AnyTransition = AnyTransition.asymmetric(
        insertion: AnyTransition.opacity.combined(with: AnyTransition.scale(scale: 0.95)).combined(with: AnyTransition.move(edge: .bottom)),
        removal: AnyTransition.opacity.combined(with: AnyTransition.scale(scale: 0.95))
    )
}