import SwiftUI

struct OnboardingMetaphor: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = OnboardingMetaphorViewModel()

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                MobileHeader(title: viewModel.title, showBack: true)

                ScrollView {
                    VStack(spacing: 32) {
                        contentBlock
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var backgroundGradient: some View {
        AppTheme.colors.background
    }

    private var contentBlock: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                OnboardingMetaphorDonutButton(
                    donutImageUrl: viewModel.donutImageUrl,
                    isExpanded: viewModel.isExpanded,
                    onTap: { viewModel.toggleExpanded() }
                )

                Text(viewModel.donutHintText)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.colors.onMuted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 384)

            if viewModel.isExpanded {
                OnboardingMetaphorMetaphorCard(
                    coupleImageUrl: viewModel.coupleImageUrl,
                    dialogs: viewModel.dialogs,
                    actionTitle: viewModel.enterHomeButtonTitle,
                    onAction: { router.completeOnboarding() }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Text(viewModel.collapsedHintText)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.colors.onMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: 384)
        .animation(.easeOut(duration: 0.5), value: viewModel.isExpanded)
    }
}

private struct OnboardingMetaphorDonutButton: View {
    let donutImageUrl: String
    let isExpanded: Bool
    let onTap: () -> Void

    @State private var pulseActive: Bool = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RemoteImage.fixed(url: donutImageUrl, width: 192, height: 192)
                    .contentMode(RemoteImageContentMode.fill)
                    .cornerRadius(96)
                    .shadow(color: AppTheme.shadow.card.color, radius: AppTheme.shadow.card.radius, x: 0, y: 4)
                    .scaleEffect(isExpanded ? 0.95 : 1.0)

                if !isExpanded {
                    Circle()
                        .fill(AppTheme.colors.primary.opacity(0.20))
                        .opacity(pulseActive ? 0.40 : 0.80)
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: pulseActive
                        )
                }
            }
            .frame(width: 192, height: 192)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("点击查看甜甜圈的寓意"))
        .accessibilityValue(Text(isExpanded ? "已展开" : "未展开"))
        .onAppear {
            pulseActive = true
        }
        .animation(.easeInOut(duration: 0.5), value: isExpanded)
    }
}

private struct OnboardingMetaphorMetaphorCard: View {
    let coupleImageUrl: String
    let dialogs: [String]
    let actionTitle: String
    let onAction: () -> Void

    var body: some View {
        AppCard {
            AppCardContent {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(spacing: 0) {
                        RemoteImage.card(url: coupleImageUrl, aspectRatio: 0.62)
                            .contentMode(RemoteImageContentMode.fill)
                            .cornerRadius(AppTheme.radius.standard)
                            .shadow(color: AppTheme.shadow.soft.color, radius: AppTheme.shadow.soft.radius, x: 0, y: 2)
                            .frame(maxWidth: 320)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(dialogs.enumerated()), id: \.offset) { pair in
                            OnboardingMetaphorDialogText(
                                text: pair.element,
                                index: pair.offset,
                                totalCount: dialogs.count
                            )
                        }
                    }

                    Rectangle()
                        .fill(AppTheme.colors.border)
                        .frame(height: 1)
                        .padding(.vertical, 16)

                    AppButton(action: onAction) {
                        HStack(spacing: 8) {
                            Text(actionTitle)
                            SafeIcon("ArrowRight", size: 18, color: AppTheme.colors.onPrimary)
                        }
                    }
                    .backgroundColor(AppTheme.colors.primary)
                    .foregroundColor(AppTheme.colors.onPrimary)
                    .cornerRadius(AppTheme.radius.small)
                    .font(size: 16, weight: .semibold)
                    .height(44)
                    .fullWidth()
                    .accessibilityLabel(Text(actionTitle))
                }
            }
            .padding(top: 24, horizontal: 24, bottom: 24)
            .spacing(16)
        }
        .background(AppTheme.colors.surface)
        .borderColor(AppTheme.colors.border)
        .cornerRadius(AppTheme.radius.standard)
        .shadow(color: AppTheme.shadow.card.color, radius: AppTheme.shadow.card.radius)
        .frame(maxWidth: 384)
    }
}

private struct OnboardingMetaphorDialogText: View {
    let text: String
    let index: Int
    let totalCount: Int

    var body: some View {
        Group {
            if isLast {
                OnboardingMetaphorGradientText(text: text)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            } else {
                Text(text)
                    .font(.system(size: 14, weight: index == 2 ? .medium : .regular))
                    .foregroundColor(resolvedColor)
                    .italic(isItalic)
                    .lineSpacing(2)
            }
        }
    }

    private var isLast: Bool {
        let lastIndex = max(0, totalCount - 1)
        return index == lastIndex
    }

    private var resolvedColor: Color {
        if index == 2 {
            return AppTheme.colors.primary
        }
        if index == 0 || index == 1 || index == 3 {
            return AppTheme.colors.onMuted
        }
        return AppTheme.colors.onSurface
    }

    private var isItalic: Bool {
        index != 2
    }
}

private struct OnboardingMetaphorGradientText: View {
    let text: String

    var body: some View {
        Text(text)
            .foregroundColor(.clear)
            .overlay(gradient.mask(Text(text)))
            .multilineTextAlignment(.center)
            .lineSpacing(2)
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [
                AppTheme.colors.primary,
                Color(hsl: 15, 1.0, 0.70)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}