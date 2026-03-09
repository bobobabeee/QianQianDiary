import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = RegisterViewModel()

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
                    registerButton
                    linkToLogin
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 48)
                .frame(maxWidth: 384)
                .frame(maxWidth: .infinity)
            }
        }
        .background(AppTheme.colors.background)
        .navigationBarBackButtonHidden(false)
    }

    private var headerView: some View {
        HStack {
            Text("注册")
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
            Text("创建账号")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppTheme.colors.onSurface)
            Text("使用手机号注册，设置密码后即可登录")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.colors.onMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }

    private var formBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("手机号")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.colors.onMuted)
                AppInput(text: $viewModel.phone, placeholder: "请输入手机号")
                    .keyboardType(.phonePad)
                    .height(48)
                    .fontSize(16)
                    .cornerRadius(AppTheme.radius.standard)
                    .borderColor(AppTheme.colors.border)
                    .focusRingColor(AppTheme.colors.primary)
                    .textColor(AppTheme.colors.onSurface)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    AppInput(text: $viewModel.smsCode, placeholder: "请输入验证码")
                        .keyboardType(.numberPad)
                        .height(48)
                        .fontSize(16)
                        .cornerRadius(AppTheme.radius.standard)
                        .borderColor(AppTheme.colors.border)
                        .focusRingColor(AppTheme.colors.primary)
                        .textColor(AppTheme.colors.onSurface)

                    Button(action: { viewModel.sendSMSCode { } }) {
                        Text(viewModel.smsCountdown > 0 ? "\(viewModel.smsCountdown)s 后重发" : "获取验证码")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(viewModel.canSendSMS ? AppTheme.colors.primary : AppTheme.colors.onMuted)
                    }
                    .disabled(!viewModel.canSendSMS)
                    .frame(width: 110, alignment: .center)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("设置密码（至少 6 位）")
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

            VStack(alignment: .leading, spacing: 8) {
                Text("确认密码")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.colors.onMuted)
                AppInput(text: $viewModel.confirmPassword, placeholder: "请再次输入密码")
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

    private var registerButton: some View {
        AppButton(action: performRegister) {
            HStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.colors.onPrimary))
                } else {
                    Text("注册并登录")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.colors.onPrimary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .backgroundColor(AppTheme.colors.primary)
        .cornerRadius(AppTheme.radius.large)
        .height(50)
        .disabled(!viewModel.canRegister || viewModel.isLoading)
        .opacity(viewModel.canRegister && !viewModel.isLoading ? 1 : 0.6)
    }

    private var linkToLogin: some View {
        Button(action: { router.navigate(to: .login, style: .root) }) {
            Text("已有账号？去登录")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.colors.primary)
        }
        .padding(.top, 8)
    }

    private func performRegister() {
        viewModel.register { [router] in
            router.completeLogin()
        }
    }
}
