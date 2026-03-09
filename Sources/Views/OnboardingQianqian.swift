import SwiftUI

struct OnboardingQianqian: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = OnboardingQianqianViewModel()

    var body: some View {
        VStack(spacing: 0) {
            MobileHeader(title: "钱钱", showBack: true)

            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 32) {
                        QianqianAvatar(
                            expression: QianqianAvatar.Expression.speaking,
                            showDialog: true,
                            dialogText: viewModel.currentStep.text,
                            size: QianqianAvatar.SizeVariant.lg
                        )

                        OnboardingQianqianStepIndicator(
                            totalCount: viewModel.steps.count,
                            currentIndex: viewModel.currentIndex
                        )
                    }
                    .padding(.bottom, 32)

                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Text(viewModel.currentStep.text)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppTheme.colors.onBackground)
                                .lineSpacing(3)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .animation(.easeOut(duration: 0.5), value: viewModel.currentIndex)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 32)
                .frame(maxWidth: 384)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 200)
            }
            .background(AppTheme.colors.background)
        }
        .safeAreaInset(edge: .bottom) {
            OnboardingQianqianBottomBar(
                canGoNext: viewModel.canGoNext,
                shouldShowContinue: viewModel.shouldShowDonutSection,
                onNext: { viewModel.goNext() },
                onContinue: { router.navigate(to: AppRouter.Destination.onboardingMetaphor, style: AppRouter.NavigationStyle.push) }
            )
        }
        .navigationBarBackButtonHidden(true)
    }
}

private struct OnboardingQianqianStepIndicator: View {
    let totalCount: Int
    let currentIndex: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<safeTotalCount, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(isActive(index) ? AppTheme.colors.primary : AppTheme.colors.muted)
                    .frame(width: isActive(index) ? 24 : 8, height: 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .animation(.easeInOut(duration: 0.3), value: currentIndex)
        .accessibilityLabel(Text("对话进度"))
        .accessibilityValue(Text(progressText))
    }

    private var safeTotalCount: Int {
        max(1, totalCount)
    }

    private func isActive(_ index: Int) -> Bool {
        index <= max(0, min(currentIndex, safeTotalCount - 1))
    }

    private var progressText: String {
        let current = max(1, min(currentIndex + 1, safeTotalCount))
        return "\(current)/\(safeTotalCount)"
    }
}

private struct OnboardingQianqianBottomBar: View {
    let canGoNext: Bool
    let shouldShowContinue: Bool
    let onNext: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    if canGoNext {
                        AppButton("下一步", action: onNext)
                            .variant(ButtonVariant.outline)
                            .foregroundColor(AppTheme.colors.onSurface)
                            .cornerRadius(AppTheme.radius.small)
                            .height(40)
                            .fullWidth()
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(Text("下一步"))
                    }

                    if shouldShowContinue {
                        AppButton("进入我的生活", action: onContinue)
                            .backgroundColor(AppTheme.colors.primary)
                            .foregroundColor(AppTheme.colors.onPrimary)
                            .cornerRadius(AppTheme.radius.small)
                            .height(40)
                            .fullWidth()
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(Text("进入我的生活"))
                    }
                }
                .frame(maxWidth: 384)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.top, 32)
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(
                colors: [
                    AppTheme.colors.background,
                    AppTheme.colors.background,
                    AppTheme.colors.background.opacity(0.0)
                ],
                startPoint: .bottom,
                endPoint: .top
            ),
            ignoresSafeAreaEdges: .bottom
        )
    }
}