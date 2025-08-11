import Foundation
import Supabase
import AuthenticationServices

@MainActor
class AuthService: ObservableObject {
    
    // Published properties to update the UI
    @Published var user: User?
    @Published var errorMessage: String?
    
    // Supabase client instance
    private let supabase: SupabaseClient
    
    init() {
        // Initialize the Supabase client from our SupabaseManager
        // Note: We will need to create/update SupabaseManager to provide a shared instance.
        self.supabase = SupabaseManager.shared.client
        
        // Check for an existing session when the service is created
        Task {
            await getCurrentSession()
        }
    }
    
    // MARK: - Core Auth Functions
    
    /// Signs a user up with email and password.
    func signUp(email: String, password: String) async -> Bool {
        do {
            let session = try await supabase.auth.signUp(email: email, password: password)
            self.user = session.user
            print("Successfully signed up user: \(session.user.email ?? "No Email")")
            return true
        } catch {
            print("Error signing up: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    /// Signs a user in with email and password.
    func signIn(email: String, password: String) async -> Bool {
        do {
            let session = try await supabase.auth.signIn(email: email, password: password)
            self.user = session.user
            print("Successfully signed in user: \(session.user.email ?? "No Email")")
            return true
        } catch {
            print("Error signing in: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    /// Signs a user out.
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            self.user = nil
            print("Successfully signed out.")
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// Checks for the current user session.
    private func getCurrentSession() async {
        do {
            let session = try await supabase.auth.session
            self.user = session.user
            print("Found existing session for user: \(session.user.email ?? "No Email")")
        } catch {
            // No active session found, which is normal.
            self.user = nil
        }
    }
    
    // MARK: - Apple Sign In

    /// Restores a persisted session from Keychain if available.
    @discardableResult
    func restoreSession() async -> Bool {
        do {
            let session = try await supabase.auth.session
            self.user = session.user
            return true
        } catch {
            self.user = nil
            return false
        }
    }
    
    /// Initiates the Sign in with Apple flow.
    func signInWithApple(credential: ASAuthorizationAppleIDCredential, nonce: String) async -> Bool {
        guard let idToken = credential.identityToken else {
            self.errorMessage = "Could not get ID token from Apple."
            return false
        }
        
        guard let idTokenString = String(data: idToken, encoding: .utf8) else {
            self.errorMessage = "Could not convert Apple ID token to string."
            return false
        }
        
        do {
            let credentials = OpenIDConnectCredentials(
                provider: .apple,
                idToken: idTokenString,
                nonce: nonce
            )
            let session = try await supabase.auth.signInWithIdToken(credentials: credentials)
            self.user = session.user
            print("Successfully signed in with Apple for user: \(session.user.email ?? "No Email")")
            return true
        } catch {
            print("Error signing in with Apple: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            return false
        }
    }
}

// MARK: - Supabase Manager (Singleton)
// We'll create a simple singleton to hold our Supabase client instance.
// This ensures we only initialize it once.

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey
        )
    }
}

