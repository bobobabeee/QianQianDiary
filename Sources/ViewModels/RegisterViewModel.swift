import SwiftUI
import Combine

@MainActor
final class RegisterViewModel: ObservableObject {
    @Published var phone: String = ""
    @Published var smsCode: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var smsCountdown: Int = 0

    private let authService: AuthService
    private var countdownTimer: Timer?

    init(authService: AuthService = AuthService.shared) {
        self.authService = authService
    }

    var canSendSMS: Bool {
        phone.trimmingCharacters(in: .whitespacesAndNewlines).count >= 11 && smsCountdown == 0
    }

    var canRegister: Bool {
        let p = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard p.count >= 11 else { return false }
        guard smsCode.trimmingCharacters(in: .whitespacesAndNewlines).count >= 4 else { return false }
        guard password.count >= 6 else { return false }
        return password == confirmPassword
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

    func register(onSuccess: @escaping () -> Void) {
        errorMessage = nil
        if password != confirmPassword {
            errorMessage = (AuthError.passwordMismatch as LocalizedError).errorDescription ?? "两次输入的密码不一致"
            return
        }
        if password.count < 6 {
            errorMessage = (AuthError.passwordTooShort as LocalizedError).errorDescription ?? "密码至少 6 位"
            return
        }
        isLoading = true
        let phoneTrimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        authService.register(phone: phoneTrimmed, code: smsCode, password: password) { [weak self] result in
            self?.isLoading = false
            switch result {
            case .success:
                onSuccess()
            case .failure(let err):
                self?.errorMessage = err.localizedDescription
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
