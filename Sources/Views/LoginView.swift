import SwiftUI

struct LoginView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView {
                VStack(spacing: 24) {
                    titleBlock
                    formBlock
                    if let msg = viewModel.errorMessage {
                        Text(msg)
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.colors.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    loginButton
                    linksRow
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 48)
                .frame(maxWidth: 384)
                .frame(maxWidth: .infinity)
            }
        }
        .background(AppTheme.colors.background)
        .navigationBarBackButtonHidden(true)
    }

    private var headerView: some View {
        HStack {
            Text("登录")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.colors.onSurface)
            Spacer()
        }
        .padding(.horizontal, AppTheme.spacing.screenHorizontal)
        .padding(.vertical, 16)
        .background(AppTheme.colors.surface)
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text("欢迎使用闪光时刻")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppTheme.colors.onSurface)
            Text("登录后，你的记录将保存在账号中，换设备也能继续查看")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.colors.onMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }

    private var formBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("用户名")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.colors.onMuted)
                AppInput(text: $viewModel.username, placeholder: "请输入用户名")
                    .height(48)
                    .fontSize(16)
                    .cornerRadius(AppTheme.radius.standard)
                    .borderColor(AppTheme.colors.border)
                    .focusRingColor(AppTheme.colors.primary)
                    .textColor(AppTheme.colors.onSurface)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("密码")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.colors.onMuted)
                AppInput(text: $viewModel.password, placeholder: "请输入密码")
                    .secure(true)
                    .height(48)
                    .fontSize(16)
                    .cornerRadius(AppTheme.radius.standard)
                    .borderColor(AppTheme.colors.border)
                    .focusRingColor(AppTheme.colors.primary)
                    .textColor(AppTheme.colors.onSurface)
            }
        }
    }

    private var loginButton: some View {
        AppButton(action: performLogin) {
            HStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.colors.onPrimary))
                } else {
                    Text("登录")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.colors.onPrimary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .backgroundColor(AppTheme.colors.primary)
        .cornerRadius(AppTheme.radius.large)
        .height(50)
        .disabled(!viewModel.canLogin || viewModel.isLoading)
        .opacity(viewModel.canLogin && !viewModel.isLoading ? 1 : 0.6)
    }

    private var linksRow: some View {
        HStack(spacing: 24) {
            Button(action: { router.navigate(to: .forgotPassword, style: .push) }) {
                Text("忘记密码？")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.colors.primary)
            }
            Spacer()
            Button(action: { router.navigate(to: .register, style: .push) }) {
                Text("还没有账号？注册")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.colors.primary)
            }
        }
        .padding(.top, 16)
    }

    private func performLogin() {
        viewModel.login { [router] in
            router.completeLogin()
        }
    }
}
