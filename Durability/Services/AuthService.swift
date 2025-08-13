import Foundation
import Supabase

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
        
        // Always clear any existing session on app start
        Task {
            await clearAllSessionData()
        }
    }
    
    // MARK: - Core Auth Functions
    
    /// Signs a user up with email and password.
    func signUp(email: String, password: String) async -> Bool {
        do {
            let session = try await supabase.auth.signUp(email: email, password: password)
            self.user = session.user
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    /// Signs a user in with email and password.
    func signIn(email: String, password: String) async -> Bool {
        do {
            let session = try await supabase.auth.signIn(email: email, password: password)
            self.user = session.user
            return true
        } catch {
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
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// Checks for the current user session.
    private func getCurrentSession() async {
        // Always return no session to force fresh sign-in
        self.user = nil
    }
    
    // MARK: - Apple Sign In
    
    /// Restores a persisted session from Keychain if available.
    @discardableResult
    func restoreSession() async -> Bool {
        // Always return false to force fresh sign-in
        self.user = nil
        return false
    }
    
    /// Signs in with Apple and creates a basic profile
    func signInWithApple(idToken: String, nonce: String, fullName: String?, email: String?) async throws {
        do {
            print("🔍 AuthService: Starting Apple Sign-In...")
            
            // Sign in with Supabase using OpenID Connect
            let response = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            
            print("✅ AuthService: Apple Sign-In successful")
            print("   - User ID: \(response.user.id.uuidString)")
            print("   - Email: \(response.user.email ?? "No email")")
            
            // Store Apple Sign-In data for onboarding
            let firstName = fullName?.components(separatedBy: " ").first
            let lastName = fullName?.components(separatedBy: " ").dropFirst().joined(separator: " ")
            
            self.appleSignInData = AppleSignInData(
                firstName: firstName,
                lastName: lastName,
                email: email
            )
            
            // Update the user property
            self.user = response.user
            
            // Debug: Check session immediately after sign-in
            do {
                let session = try await supabase.auth.session
                print("✅ AuthService: Session verified after sign-in")
                print("   - Session user ID: \(session.user.id.uuidString)")
                print("   - Access token exists: \(session.accessToken.isEmpty ? "No" : "Yes")")
            } catch {
                print("❌ AuthService: Session check failed after sign-in: \(error)")
            }
            
            // Create basic profile if we have name data
            if let fullName = fullName, !fullName.isEmpty {
                await createBasicProfileFromAppleSignIn(
                    appleData: self.appleSignInData!,
                    userId: response.user.id.uuidString
                )
            }
            
        } catch {
            print("❌ AuthService: Apple Sign-In failed: \(error)")
            throw error
        }
    }
    
    /// Creates a basic profile in Supabase with Apple Sign-In data
    private func createBasicProfileFromAppleSignIn(appleData: AppleSignInData, userId: String) async {
        do {
            print("🔍 AuthService: Creating basic profile for user: \(userId)")
            print("   - First name: \(appleData.firstName ?? "nil")")
            print("   - Last name: \(appleData.lastName ?? "nil")")
            
            // Use direct database write
            struct ProfileInsertData: Codable {
                let id: String
                let firstName: String
                let lastName: String
                let isPilot: Bool
                let onboardingCompleted: Bool
                let assessmentCompleted: Bool
                let createdAt: String
                let updatedAt: String
                
                enum CodingKeys: String, CodingKey {
                    case id
                    case firstName = "first_name"
                    case lastName = "last_name"
                    case isPilot = "is_pilot"
                    case onboardingCompleted = "onboarding_completed"
                    case assessmentCompleted = "assessment_completed"
                    case createdAt = "created_at"
                    case updatedAt = "updated_at"
                }
            }
            
            let insertData = ProfileInsertData(
                id: userId,
                firstName: appleData.firstName ?? "",
                lastName: appleData.lastName ?? "",
                isPilot: true,
                onboardingCompleted: false,
                assessmentCompleted: false,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            try await SupabaseManager.shared.client
                .from("profiles")
                .upsert(insertData)
                .execute()
            
            print("✅ AuthService: Basic profile created successfully")
            
        } catch {
            print("❌ AuthService: Failed to create basic profile: \(error)")
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
        } catch {
            // Ignore errors - we want to clear regardless
        }
        
        // Always clear user data
        self.user = nil
        self.appleSignInData = nil
        
        // Clear any stored session data
        UserDefaults.standard.removeObject(forKey: "supabase.auth.token")
        UserDefaults.standard.removeObject(forKey: "supabase.auth.refreshToken")
        UserDefaults.standard.removeObject(forKey: "supabase.auth.expiresAt")
        UserDefaults.standard.removeObject(forKey: "supabase.auth.user")
    }
    
    /// Checks if there's an existing session
    func hasExistingSession() -> Bool {
        // Always return false to force fresh sign-in
        return false
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
        // Initialize client with URL and key directly
        self.client = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey
        )
    }
    
    /// Get a fresh client instance (useful for testing)
    func getFreshClient() -> SupabaseClient {
        return SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey
        )
    }
    
    /// Check if the client is properly configured
    func isConfigured() -> Bool {
        return !Config.supabaseAnonKey.isEmpty && Config.supabaseURL.absoluteString != ""
    }
}

