import SwiftUI

/// 我的：查看账号、退出登录、注销账号
struct ProfileView: View {
    @EnvironmentObject var router: AppRouter
    @State private var showLogoutConfirm = false
    @State private var showDeleteAccountConfirm = false
    @State private var isDeletingAccount = false
    @State private var deleteAccountErrorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            MobileHeader(title: "我的", showBack: false)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    accountSection
                    Divider().overlay(AppTheme.colors.border).padding(.vertical, 8)
                    logoutSection
                    Divider().overlay(AppTheme.colors.border).padding(.vertical, 8)
                    deleteAccountSection
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
        .confirmationDialog("注销账号", isPresented: $showDeleteAccountConfirm, titleVisibility: .visible) {
            Button("注销账号", role: .destructive) { performDeleteAccount() }
            Button("取消", role: .cancel) { }
        } message: {
            Text("注销后账号数据将被删除且无法恢复，确定继续？")
        }
        .alert("操作失败", isPresented: Binding(
            get: { deleteAccountErrorMessage != nil },
            set: { if !$0 { deleteAccountErrorMessage = nil } }
        )) {
            Button("好的", role: .cancel) { deleteAccountErrorMessage = nil }
        } message: {
            Text(deleteAccountErrorMessage ?? "")
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

    private var deleteAccountSection: some View {
        Button(action: { showDeleteAccountConfirm = true }) {
            HStack {
                Text("注销账号")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.colors.error)
                Spacer()
                if isDeletingAccount {
                    ProgressView()
                        .scaleEffect(0.9)
                } else {
                    SafeIcon("ChevronRight", size: 18, color: AppTheme.colors.onMuted)
                }
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDeletingAccount)
    }

    private var maskedPhone: String {
        let id = AuthService.shared.currentPhone
        if id.count >= 11 {
            return String(id.prefix(3)) + "****" + String(id.suffix(4))
        }
        if id.count > 2 {
            return String(id.prefix(1)) + String(repeating: "*", count: id.count - 2) + String(id.suffix(1))
        }
        return id
    }

    private func performLogout() {
        AuthService.shared.logout()
        router.completeLogout()
    }

    private func performDeleteAccount() {
        isDeletingAccount = true
        AuthService.shared.deleteAccount { result in
            isDeletingAccount = false
            switch result {
            case .success:
                AuthService.shared.logout()
                router.completeLogout()
            case .failure(let error):
                deleteAccountErrorMessage = error.localizedDescription
            }
        }
    }
}
