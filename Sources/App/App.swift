import SwiftUI

extension Notification.Name {
    /// App 进入前台或冷启动后由 `AppRootContent` 发出，首页等可据此拉取最新数据
    static let appShouldSyncData = Notification.Name("appShouldSyncData")
}

@main
struct QianqianDiaryApp: App {
    @StateObject private var router = AppRouter()

    init() {
        APIConfig.applyDefaultRegionIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            AppRootContent()
                .environmentObject(router)
        }
    }
}

private struct AppRootContent: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        router.rootView()
            .onChange(of: scenePhase) { newPhase in
                guard newPhase == .active, AuthService.shared.isLoggedIn else { return }
                NotificationCenter.default.post(name: .appShouldSyncData, object: nil)
            }
    }
}
