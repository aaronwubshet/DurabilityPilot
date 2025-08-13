import SwiftUI
import AuthenticationServices
import CryptoKit

struct AuthenticationView: View {
    let authService: AuthService
    @StateObject private var viewModel: AuthenticationViewModel
    @EnvironmentObject var appState: AppState
    @State private var currentNonce: String? = nil
    
    init(authService: AuthService) {
        self.authService = authService
        self._viewModel = StateObject(wrappedValue: AuthenticationViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                // App Logo
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 80))
                    .foregroundColor(.electricGreen)
                
                Text("Welcome to Durability")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.lightText)
                
                Text("Sign in with Apple to continue")
                    .font(.headline)
                    .foregroundColor(.secondaryText)
                
                Spacer()
                
                // Sign in with Apple Button
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
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .cornerRadius(8)
                
                // Privacy Policy and Terms Agreement
                VStack(spacing: 8) {
                    Text("By continuing forward, you agree to Durability's")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 4) {
                        Link("Privacy Policy", destination: URL(string: "https://www.mydurability.ai/privacy-policy.html")!)
                            .font(.caption)
                            .foregroundColor(.electricGreen)
                        
                        Text("and")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                        
                        Link("Terms & Conditions", destination: URL(string: "https://www.mydurability.ai/terms.html")!)
                            .font(.caption)
                            .foregroundColor(.electricGreen)
                    }
                }
                .padding(.horizontal)
                
                if viewModel.isLoading {
                    ProgressView("Signing in...")
                        .padding()
                        .foregroundColor(.lightText)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .background(Color.darkSpaceGrey)
        }
        .background(Color.darkSpaceGrey)
    }
    
    // MARK: - Apple Sign-In Helper Methods
    
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
    
    private func handleSignInWithAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    print("Invalid state: A login callback was received, but no login request was sent.")
                    return
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetch identity token")
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                    return
                }
                
                Task {
                    do {
                        // Convert PersonNameComponents to String
                        let fullNameString: String?
                        if let fullName = appleIDCredential.fullName {
                            let formatter = PersonNameComponentsFormatter()
                            fullNameString = formatter.string(from: fullName)
                        } else {
                            fullNameString = nil
                        }
                        
                        try await authService.signInWithApple(
                            idToken: idTokenString,
                            nonce: nonce,
                            fullName: fullNameString,
                            email: appleIDCredential.email
                        )
                        
                        await appState.updateAuthenticationStatus()
                    } catch {
                        print("Sign in with Apple failed: \(error.localizedDescription)")
                    }
                }
            }
        case .failure(let error):
            print("Sign in with Apple failed: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AuthenticationView(authService: AuthService())
        .environmentObject(AppState())
}

