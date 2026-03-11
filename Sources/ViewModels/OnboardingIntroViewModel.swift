import SwiftUI

@MainActor
final class OnboardingIntroViewModel: ObservableObject {
    struct OnboardingIntroCoreValue {
        let icon: String
        let title: String
        let description: String
    }

    @Published private var valuesSource: [OnboardingIntroCoreValue] = [
        OnboardingIntroCoreValue(icon: "📝", title: "记录成功", description: "每日记录微小成就,发现自身优势"),
        OnboardingIntroCoreValue(icon: "🎯", title: "视觉化目标", description: "用愿景板呈现梦想,强化目标承诺"),
        OnboardingIntroCoreValue(icon: "✨", title: "美德践行", description: "培养内在品格,实现自我成长")
    ]

    var coreValues: [OnboardingIntroCoreValue] {
        valuesSource
    }

    func startExplore(router: AppRouter) {
        router.navigate(to: AppRouter.Destination.onboardingQianqian, style: AppRouter.NavigationStyle.push)
    }
}