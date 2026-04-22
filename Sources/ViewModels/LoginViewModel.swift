import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let authService: AuthService

    init(authService: AuthService = AuthService.shared) {
        self.authService = authService
    }

    var canLogin: Bool {
        let u = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return !u.isEmpty && !password.isEmpty
    }

    func login(onSuccess: @escaping () -> Void) {
        errorMessage = nil
        isLoading = true
        let usernameTrimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        authService.login(username: usernameTrimmed, password: password) { [weak self] result in
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
