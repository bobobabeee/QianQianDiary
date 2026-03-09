import SwiftUI

/// 我的：查看账号、退出登录
struct ProfileView: View {
    @EnvironmentObject var router: AppRouter
    @State private var showLogoutConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            MobileHeader(title: "我的", showBack: false)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    accountSection
                    Divider().overlay(AppTheme.colors.border).padding(.vertical, 8)
                    logoutSection
                }
                .padding(.horizontal, AppTheme.spacing.screenHorizontal)
                .padding(.vertical, AppTheme.spacing.lg)
                .frame(maxWidth: AppTheme.spacing.contentMaxWidth)
                .frame(maxWidth: .infinity)
            }
            .background(AppTheme.colors.background)
        }
        .background(AppTheme.colors.background)
        .safeAreaInset(edge: .bottom) {
            MobileBottomNav(activeDestination: AppRouter.Destination.profile)
        }
        .navigationBarBackButtonHidden(true)
        .confirmationDialog("退出登录", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("退出", role: .destructive) { performLogout() }
            Button("取消", role: .cancel) { }
        } message: {
            Text("退出后需重新登录才能查看你的记录")
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("当前账号")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.colors.onMuted)
            Text(maskedPhone)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.colors.onSurface)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
    }

    private var logoutSection: some View {
        Button(action: { showLogoutConfirm = true }) {
            HStack {
                Text("退出登录")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.colors.error)
                Spacer()
                SafeIcon("ChevronRight", size: 18, color: AppTheme.colors.onMuted)
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var maskedPhone: String {
        let phone = AuthService.shared.currentPhone
        guard phone.count >= 11 else { return phone }
        let start = phone.prefix(3)
        let end = phone.suffix(4)
        return "\(start)****\(end)"
    }

    private func performLogout() {
        AuthService.shared.logout()
        router.completeLogout()
    }
}
