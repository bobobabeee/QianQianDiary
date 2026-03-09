import SwiftUI
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    enum LoginMode: String, CaseIterable {
        case password = "密码登录"
        case sms = "验证码登录"
    }

    @Published var phone: String = ""
    @Published var password: String = ""
    @Published var smsCode: String = ""
    @Published var loginMode: LoginMode = .password
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var smsCountdown: Int = 0

    private let authService: AuthService
    private var countdownTimer: Timer?
    private var countdownSubscription: AnyCancellable?

    init(authService: AuthService = AuthService.shared) {
        self.authService = authService
    }

    var canSendSMS: Bool {
        phone.trimmingCharacters(in: .whitespacesAndNewlines).count >= 11 && smsCountdown == 0
    }

    var canLogin: Bool {
        let p = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard p.count >= 11 else { return false }
        switch loginMode {
        case .password:
            return !password.isEmpty
        case .sms:
            return smsCode.trimmingCharacters(in: .whitespacesAndNewlines).count >= 4
        }
    }

    func sendSMSCode(completion: @escaping () -> Void) {
        errorMessage = nil
        authService.sendSMSCode(phone: phone) { [weak self] result in
            switch result {
            case .success:
                self?.smsCountdown = 60
                self?.startCountdown()
                completion()
            case .failure(let err):
                self?.errorMessage = err.localizedDescription
                completion()
            }
        }
    }

    func login(onSuccess: @escaping () -> Void) {
        errorMessage = nil
        isLoading = true
        let phoneTrimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        switch loginMode {
        case .password:
            authService.login(phone: phoneTrimmed, password: password) { [weak self] result in
                self?.isLoading = false
                switch result {
                case .success:
                    onSuccess()
                case .failure(let err):
                    self?.errorMessage = err.localizedDescription
                }
            }
        case .sms:
            authService.login(phone: phoneTrimmed, code: smsCode) { [weak self] result in
                self?.isLoading = false
                switch result {
                case .success:
                    onSuccess()
                case .failure(let err):
                    self?.errorMessage = err.localizedDescription
                }
            }
        }
    }

    private func startCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.smsCountdown <= 1 {
                    self.countdownTimer?.invalidate()
                    self.countdownTimer = nil
                    self.smsCountdown = 0
                } else {
                    self.smsCountdown -= 1
                }
            }
        }
        RunLoop.main.add(countdownTimer!, forMode: .common)
    }

    deinit {
        countdownTimer?.invalidate()
    }
}
