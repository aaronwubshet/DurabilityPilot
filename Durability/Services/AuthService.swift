import Foundation
import Supabase
import AuthenticationServices

@MainActor
class AuthService: ObservableObject {
    
    // Published properties to update the UI
    @Published var user: User?
    @Published var errorMessage: String?
    
    // Apple Sign-In data storage
    @Published var appleSignInData: AppleSignInData?
    
    // Supabase client instance
    private let supabase: SupabaseClient
    
    init() {
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
            print("AuthService: Successfully signed up user: \(session.user.email ?? "No Email")")
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
            print("AuthService: Successfully signed in user: \(session.user.email ?? "No Email")")
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
            self.appleSignInData = nil
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
    
    /// Signs in with Apple and creates a basic profile
    func signInWithApple(idToken: String, nonce: String, fullName: String?, email: String?) async throws {
        print("AuthService: Signing in with Apple...")
        
        do {
            // Sign in with Supabase using OpenID Connect
            let response = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            
            // Store Apple Sign-In data for onboarding
            let firstName = fullName?.components(separatedBy: " ").first
            let lastName = fullName?.components(separatedBy: " ").dropFirst().joined(separator: " ")
            
            print("AuthService: Extracted name data - firstName: '\(firstName ?? "nil")', lastName: '\(lastName ?? "nil")'")
            
            self.appleSignInData = AppleSignInData(
                firstName: firstName,
                lastName: lastName,
                email: email
            )
            
            // Update the user property
            self.user = response.user
            
            print("AuthService: Successfully signed in with Apple")
            print("AuthService: User ID: \(response.user.id)")
            print("AuthService: User Email: \(response.user.email ?? "No Email")")
            
            // Debug: Check session immediately after sign-in
            do {
                let session = try await supabase.auth.session
                print("AuthService: Session check - User ID: \(session.user.id)")
                print("AuthService: Session check - Access Token: \(session.accessToken.prefix(20))...")
            } catch {
                print("AuthService: Session check failed: \(error)")
            }
            
            // Create basic profile if we have name data
            if let fullName = fullName, !fullName.isEmpty {
                await createBasicProfileFromAppleSignIn(
                    appleData: self.appleSignInData!,
                    userId: response.user.id.uuidString
                )
            }
            
        } catch {
            print("AuthService: Apple Sign-In failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Creates a basic profile in Supabase with Apple Sign-In data
    private func createBasicProfileFromAppleSignIn(appleData: AppleSignInData, userId: String) async {
        do {
            print("AuthService: Creating basic profile...")
            print("AuthService: Writing firstName: '\(appleData.firstName ?? "nil")', lastName: '\(appleData.lastName ?? "nil")' to database")
            
            // Use direct database write like in DatabaseTestView
            try await SupabaseManager.shared.client
                .from("profiles")
                .upsert([
                    "id": userId,
                    "first_name": appleData.firstName ?? "",
                    "last_name": appleData.lastName ?? ""
                ])
                .execute()
            
            print("AuthService: Basic profile created successfully")
            
        } catch {
            print("AuthService: Failed to create basic profile: \(error.localizedDescription)")
            // Don't throw here - profile creation failure shouldn't break sign-in
        }
    }
    
    /// Retrieves Apple Sign-In data for onboarding
    func getAppleSignInData() -> AppleSignInData? {
        return appleSignInData
    }
    
    /// Clears Apple Sign-In data after it's been used in onboarding
    func clearAppleSignInData() {
        appleSignInData = nil
    }
    
    /// Clears all session data and forces a fresh sign-in
    func clearAllSessionData() async {
        do {
            try await supabase.auth.signOut()
            self.user = nil
            self.appleSignInData = nil
            print("AuthService: Session data cleared")
        } catch {
            print("AuthService: Error clearing session: \(error.localizedDescription)")
        }
    }
    
    /// Checks if there's an existing session
    func hasExistingSession() -> Bool {
        return user != nil
    }
}

// MARK: - Apple Sign-In Data Model
struct AppleSignInData {
    let firstName: String?
    let lastName: String?
    let email: String?
}

// MARK: - Supabase Manager (Singleton)
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

