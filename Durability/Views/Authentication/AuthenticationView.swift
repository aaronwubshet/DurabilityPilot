import SwiftUI
import AuthenticationServices
import CryptoKit

struct AuthenticationView: View {
    
    let authService: AuthService
    @StateObject private var viewModel: AuthenticationViewModel
    @State private var currentNonce: String?
    @EnvironmentObject var appState: AppState
    
    init(authService: AuthService) {
        self.authService = authService
        self._viewModel = StateObject(wrappedValue: AuthenticationViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                Spacer()
                
                // Your App Logo Here
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                
                Text("Welcome to Durability")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign in with Apple to continue.")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Sign In with Apple Button
                SignInWithAppleButton { request in
                    // Configure the request
                    request.requestedScopes = [.fullName, .email]
                    
                    // Generate nonce for security
                    let nonce = randomNonceString()
                    currentNonce = nonce
                    request.nonce = sha256(nonce)
                } onCompletion: { result in
                    handleSignInWithAppleResult(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 55)
                .cornerRadius(10)
                
                if viewModel.isLoading {
                    ProgressView("Signing in...")
                        .padding()
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .padding()
        }
    }
    
    private func handleSignInWithAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    viewModel.errorMessage = "Invalid state: A login callback was received, but no login request was sent."
                    return
                }
                
                Task {
                    let success = await viewModel.signInWithApple(credential: appleIDCredential, nonce: nonce)
                    if success {
                        // Successfully signed in - update app state
                        await appState.updateAuthenticationStatus()
                        print("Successfully signed in with Apple")
                    }
                }
            }
        case .failure(let error):
            viewModel.errorMessage = "Sign in with Apple failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Security Helpers
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

#Preview {
    AuthenticationView(authService: AuthService())
        .environmentObject(AppState())
}

