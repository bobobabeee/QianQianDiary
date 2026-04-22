import SwiftUI
import Combine

@MainActor
final class RegisterViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let authService: AuthService

    init(authService: AuthService = AuthService.shared) {
        self.authService = authService
    }

    var canRegister: Bool {
        let u = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !u.isEmpty else { return false }
        guard password.count >= 6 else { return false }
        return password == confirmPassword
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
        let u = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !u.isEmpty else {
            errorMessage = (AuthError.invalidUsername as LocalizedError).errorDescription ?? "请输入用户名"
            return
        }
        isLoading = true
        authService.register(username: u, password: password) { [weak self] result in
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
