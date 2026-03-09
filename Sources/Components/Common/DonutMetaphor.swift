import SwiftUI
import Foundation

struct DonutMetaphor: View {
    var isExpanded: Bool = false
    var onToggle: (() -> Void)? = nil

    @State private var expanded: Bool = false
    @State private var pingAnimating: Bool = false

    private let donutImageUrl = "https://spark-builder.s3.cn-north-1.amazonaws.com.cn/image/2026/3/4/a5c896d8-7399-4f5e-9893-a285aeac0d94.png"
    private let coupleImageUrl = "https://spark-builder.s3.cn-north-1.amazonaws.com.cn/image/2026/3/4/d8e6b386-c0bd-4837-9d4e-8f6e8eec8573.png"

    var body: some View {
        VStack(spacing: 24) {
            DonutButton(
                donutImageUrl: donutImageUrl,
                expanded: expanded,
                pingAnimating: pingAnimating,
                onTap: handleTap
            )

            if expanded {
                MetaphorCard(coupleImageUrl: coupleImageUrl)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .onAppear {
            expanded = isExpanded
            updatePingAnimation()
        }
        .onChange(of: expanded) { _ in
            updatePingAnimation()
        }
        .animation(.easeOut(duration: 0.5), value: expanded)
    }

    private func handleTap() {
        expanded.toggle()
        onToggle?()
    }

    private func updatePingAnimation() {
        if expanded {
            pingAnimating = false
        } else {
            pingAnimating = true
        }
    }
}

private struct DonutButton: View {
    let donutImageUrl: String
    let expanded: Bool
    let pingAnimating: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RemoteImage.fixed(url: donutImageUrl, width: 192, height: 192)
                    .contentMode(RemoteImageContentMode.fill)
                    .cornerRadius(96)
                    .shadow(color: AppTheme.shadow.card.color, radius: AppTheme.shadow.card.radius, x: 0, y: 4)
                    .scaleEffect(expanded ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: expanded)

                if !expanded {
                    Circle()
                        .fill(AppTheme.colors.primary.opacity(0.20))
                        .scaleEffect(pingAnimating ? 1.35 : 1.0)
                        .opacity(pingAnimating ? 0.0 : 1.0)
                        .animation(
                            .easeOut(duration: 2.0).repeatForever(autoreverses: false),
                            value: pingAnimating
                        )
                }
            }
            .frame(width: 192, height: 192)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("点击查看甜甜圈的寓意"))
        .accessibilityValue(Text(expanded ? "已展开" : "未展开"))
        .accessibilityAddTraits(.isButton)
        .onAppear { }
    }
}

private struct MetaphorCard: View {
    let coupleImageUrl: String

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 0) {
                    RemoteImage.card(url: coupleImageUrl, aspectRatio: 0.62)
                        .contentMode(RemoteImageContentMode.fill)
                        .cornerRadius(AppTheme.radius.standard)
                        .frame(maxWidth: 280)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .leading, spacing: 12) {
                    QuoteText("“甜甜圈中间的圆孔代表着人类的内心,可是这内心本身却是无形的。”", isEmphasis: false, isMuted: true)
                    QuoteText("“许多人并不关心自己的内心,就是因为看不到它。对于他们来说,只有看得见的成功才是重要的。”", isEmphasis: false, isMuted: false)
                    QuoteText("“但你如果想要变得幸福,就不能只重视物质上的成功,还必须培养自己具有优秀的内心。”", isEmphasis: true, isMuted: false)
                    QuoteText("“没有圆圈也就没有圆孔。对于人们来说,它则意味着:绝不能忽视圆圈,否则的话内心也无法彰显出来。”", isEmphasis: false, isMuted: false)

                    Text("完满而幸福的人都是两者兼备的。")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.colors.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
                .font(.system(size: 14))
                .foregroundColor(AppTheme.colors.onSurface)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(AppTheme.colors.surface)
        .borderColor(AppTheme.colors.border)
        .cornerRadius(AppTheme.radius.standard)
        .shadow(color: AppTheme.shadow.card.color, radius: AppTheme.shadow.card.radius)
        .frame(maxWidth: 384)
    }
}

private struct QuoteText: View {
    let text: String
    let isEmphasis: Bool
    let isMuted: Bool

    init(_ text: String, isEmphasis: Bool, isMuted: Bool) {
        self.text = text
        self.isEmphasis = isEmphasis
        self.isMuted = isMuted
    }

    var body: some View {
        Text(text)
            .foregroundColor(resolvedColor)
            .font(.system(size: 14, weight: isEmphasis ? .medium : .regular))
            .lineSpacing(2)
    }

    private var resolvedColor: Color {
        if isEmphasis {
            return AppTheme.colors.primary
        }
        if isMuted {
            return AppTheme.colors.onMuted
        }
        return AppTheme.colors.onSurface
    }
}