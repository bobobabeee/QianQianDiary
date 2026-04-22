import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var router: AppRouter
    @State private var showLogoutConfirm = false
    @State private var showDeleteAccountConfirm = false
    @State private var isDeletingAccount = false
    @State private var deleteAccountErrorMessage: String?
    @State private var serverRegion: APIServerRegion = APIConfig.selectedServerRegion

    var body: some View {
        VStack(spacing: 0) {
            MobileHeader(title: "设置", showBack: true)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    serverRegionSection
                    Divider().overlay(AppTheme.colors.border).padding(.vertical, 8)
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
        .navigationBarBackButtonHidden(true)
        .onAppear { serverRegion = APIConfig.selectedServerRegion }
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

    private var serverRegionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("服务器线路")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.colors.onMuted)
            Picker("服务器线路", selection: $serverRegion) {
                ForEach(APIServerRegion.allCases) { region in
                    Text(region.title).tag(region)
                }
            }
            .pickerStyle(.segmented)
            Text("切换线路后将退出登录，需在新节点重新登录；账号数据以各服务器为准。")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.colors.onMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .onChange(of: serverRegion) { newValue in
            applyServerRegionChange(newValue)
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

    private func applyServerRegionChange(_ newValue: APIServerRegion) {
        guard newValue != APIConfig.selectedServerRegion else { return }
        APIConfig.setServerRegion(newValue)
        if AuthService.shared.isLoggedIn {
            AuthService.shared.logout()
            router.completeLogout()
        }
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
