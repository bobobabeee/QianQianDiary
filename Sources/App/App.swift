import SwiftUI

@main
struct QianqianDiaryApp: App {
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            router.rootView()
                .environmentObject(router)
        }
    }
}
