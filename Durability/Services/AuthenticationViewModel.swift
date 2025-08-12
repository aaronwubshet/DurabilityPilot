import Foundation
import Combine
import AuthenticationServices

@MainActor
class AuthenticationViewModel: ObservableObject {
    
    // Input fields
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = "" // For sign up
    
    // State management
    @Published var canSubmit = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Services
    private let authService: AuthService
    
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthService) {
        self.authService = authService
        
        // Validation logic for the sign-in form
        Publishers.CombineLatest($email, $password)
            .map { email, password in
                !email.isEmpty && !password.isEmpty && password.count >= 6
            }
            .assign(to: \.canSubmit, on: self)
            .store(in: &cancellables)
        
        // Listen for error messages from the auth service
        authService.$errorMessage
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - User Actions
    
    func signIn() async -> Bool {
        isLoading = true
        let success = await authService.signIn(email: email, password: password)
        isLoading = false
        return success
    }
    
    func signUp() async -> Bool {
        guard password == confirmPassword else {
            self.errorMessage = "Passwords do not match."
            return false
        }
        
        isLoading = true
        let success = await authService.signUp(email: email, password: password)
        isLoading = false
        return success
    }
}

