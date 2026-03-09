import SwiftUI

struct OnboardingIntro: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var viewModel = OnboardingIntroViewModel()

    var body: some View {
        ZStack {
            OnboardingIntroBackground()

            GeometryReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)

                        OnboardingIntroHeroView(
                            coreValues: viewModel.coreValues,
                            onStart: { viewModel.startExplore(router: router) }
                        )
                        .frame(maxWidth: 448)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)

                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: proxy.size.height)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

private struct OnboardingIntroBackground: View {
    var body: some View {
        AppTheme.colors.background
            .ignoresSafeArea()
    }
}

private struct OnboardingIntroHeroView: View {
    let coreValues: [OnboardingIntroViewModel.OnboardingIntroCoreValue]
    let onStart: () -> Void

    @State private var showTitle: Bool = false
    @State private var showSubtitle: Bool = false
    @State private var showImage: Bool = false
    @State private var showValues: Bool = false
    @State private var showButton: Bool = false
    @State private var showHint: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                OnboardingIntroGradientText(text: "✨", fontSize: 60, weight: .bold)
            }
            .padding(.bottom, 32)

            titleBlock
                .padding(.bottom, 24)

            subtitleBlock
                .padding(.bottom, 32)

            brandImageBlock
                .padding(.bottom, 32)

            coreValuesBlock
                .padding(.bottom, 32)

            startButtonBlock
                .padding(.bottom, 16)

            hintBlock
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .onAppear(perform: runAppearSequence)
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text("闪光时刻")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.colors.onBackground)

            Text("GlowMoment")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.colors.primary)
        }
        .multilineTextAlignment(.center)
        .opacity(showTitle ? 1 : 0)
        .offset(y: showTitle ? 0 : 16)
        .animation(.easeOut(duration: 0.7), value: showTitle)
    }

    private var subtitleBlock: some View {
        Text("用积极有爱的视角去生活,\n发现自身优势,提升自我价值")
            .font(.system(size: 16))
            .foregroundColor(AppTheme.colors.onMuted)
            .lineSpacing(3)
            .multilineTextAlignment(.center)
            .opacity(showSubtitle ? 1 : 0)
            .offset(y: showSubtitle ? 0 : 16)
            .animation(.easeOut(duration: 0.7), value: showSubtitle)
    }

    private var brandImageBlock: some View {
        VStack(spacing: 0) {
            Image("onboarding_puppy")
                .resizable()
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .cornerRadius(18)
                .shadow(color: AppTheme.shadow.card.color, radius: AppTheme.shadow.card.radius, x: 0, y: 4)
                .accessibilityLabel(Text("钱钱与成功日记"))
        }
        .frame(maxWidth: 320)
        .opacity(showImage ? 1 : 0)
        .scaleEffect(showImage ? 1.0 : 0.95)
        .animation(.easeOut(duration: 0.7), value: showImage)
    }

    private var coreValuesBlock: some View {
        VStack(spacing: 12) {
            ForEach(Array(coreValues.enumerated()), id: \.offset) { pair in
                OnboardingIntroCoreValueCard(value: pair.element)
            }
        }
        .frame(maxWidth: .infinity)
        .opacity(showValues ? 1 : 0)
        .offset(y: showValues ? 0 : 16)
        .animation(.easeOut(duration: 0.7), value: showValues)
    }

    private var startButtonBlock: some View {
        AppButton("开始探索", action: onStart)
            .backgroundColor(AppTheme.colors.primary)
            .foregroundColor(AppTheme.colors.onPrimary)
            .cornerRadius(AppTheme.radius.pill)
            .font(size: 16, weight: .semibold)
            .height(48)
            .fullWidth()
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 16)
            .animation(.easeOut(duration: 0.7), value: showButton)
            .accessibilityLabel(Text("开始探索"))
    }

    private var hintBlock: some View {
        Text("与拉布拉多\"钱钱\"一起开启成长之旅")
            .font(.system(size: 12))
            .foregroundColor(AppTheme.colors.onMuted)
            .multilineTextAlignment(.center)
            .opacity(showHint ? 1 : 0)
            .animation(.easeOut(duration: 0.7), value: showHint)
    }

    private func runAppearSequence() {
        showTitle = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            showSubtitle = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            showImage = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            showValues = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
            showButton = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) {
            showHint = true
        }
    }
}

private struct OnboardingIntroCoreValueCard: View {
    let value: OnboardingIntroViewModel.OnboardingIntroCoreValue

    var body: some View {
        AppCard {
            HStack(alignment: .top, spacing: 12) {
                Text(value.icon)
                    .font(.system(size: 24))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(value.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.colors.onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(value.description)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.colors.onMuted)
                        .lineSpacing(2)
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(AppTheme.colors.surface)
        .borderColor(AppTheme.colors.border)
        .cornerRadius(AppTheme.radius.standard)
        .shadow(color: AppTheme.shadow.soft.color, radius: AppTheme.shadow.soft.radius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(value.title)，\(value.description)"))
    }
}

private struct OnboardingIntroGradientText: View {
    let text: String
    let fontSize: CGFloat
    let weight: Font.Weight

    var body: some View {
        LinearGradient(
            colors: [
                AppTheme.colors.primary,
                Color(hsl: 15, 1.0, 0.70)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .mask(
            Text(text)
                .font(.system(size: fontSize, weight: weight))
        )
        .accessibilityHidden(true)
    }
}