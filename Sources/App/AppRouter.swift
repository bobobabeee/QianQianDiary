import SwiftUI

final class AppRouter: ObservableObject {
    private let onboardingCompletedKey = "hasCompletedOnboarding"

    @Published var root: AppRouter.Destination = AppRouter.Destination.home
    @Published var path = NavigationPath()

    enum Destination: Hashable {
        case diaryCalendarView(date: String? = nil)
        case forgotPassword
        case home
        case login
        case onboardingIntro
        case onboardingMetaphor
        case onboardingQianqian
        case profile
        case register
        case settings
        case successDiaryEditor
        case successDiaryStats
        case virtueGrowthStats
        case virtueLogEditor
        case visionBoardEditor(id: String? = nil)
        case visionBoardMain
        case visionSharePreview(id: String)
    }

    enum NavigationStyle {
        case push
        case root
    }

    init() {
        if !UserDefaults.standard.bool(forKey: onboardingCompletedKey) {
            root = AppRouter.Destination.onboardingIntro
        } else if !AuthService.shared.isLoggedIn {
            root = AppRouter.Destination.login
        } else {
            root = AppRouter.Destination.home
        }
    }

    @ViewBuilder
    func rootView() -> some View {
        let pathBinding = Binding<NavigationPath>(
            get: { self.path },
            set: { self.path = $0 }
        )

        NavigationStack(path: pathBinding) {
            self.view(for: root)
                .navigationDestination(for: AppRouter.Destination.self) { destination in
                    self.view(for: destination)
                }
        }
    }

    @ViewBuilder
    func view(for destination: AppRouter.Destination) -> some View {
        switch destination {
        case AppRouter.Destination.diaryCalendarView(let date):
            DiaryCalendarView(date: date)

        case AppRouter.Destination.forgotPassword:
            ForgotPasswordView()

        case AppRouter.Destination.home:
            Home()

        case AppRouter.Destination.login:
            LoginView()

        case AppRouter.Destination.onboardingIntro:
            OnboardingIntro()

        case AppRouter.Destination.onboardingMetaphor:
            OnboardingMetaphor()

        case AppRouter.Destination.onboardingQianqian:
            OnboardingQianqian()

        case AppRouter.Destination.profile:
            ProfileView()

        case AppRouter.Destination.register:
            RegisterView()

        case AppRouter.Destination.settings:
            SettingsView()

        case AppRouter.Destination.successDiaryEditor:
            SuccessDiaryEditor()

        case AppRouter.Destination.successDiaryStats:
            SuccessDiaryStats()

        case AppRouter.Destination.virtueGrowthStats:
            VirtueGrowthStats()

        case AppRouter.Destination.virtueLogEditor:
            VirtueLogEditor()

        case AppRouter.Destination.visionBoardEditor(let id):
            VisionBoardEditor(id: id)

        case AppRouter.Destination.visionBoardMain:
            VisionBoardMain()

        case AppRouter.Destination.visionSharePreview(let id):
            VisionSharePreview(id: id)
        }
    }

    func navigate(
        to destination: AppRouter.Destination,
        style: AppRouter.NavigationStyle = AppRouter.NavigationStyle.push
    ) {
        switch style {
        case AppRouter.NavigationStyle.push:
            path.append(destination)
        case AppRouter.NavigationStyle.root:
            root = destination
            path = NavigationPath()
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
        root = AppRouter.Destination.login
        path = NavigationPath()
    }

    func completeLogin() {
        root = AppRouter.Destination.home
        path = NavigationPath()
    }

    /// 退出登录后回到登录页
    func completeLogout() {
        root = AppRouter.Destination.login
        path = NavigationPath()
    }

    func dismiss() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
}