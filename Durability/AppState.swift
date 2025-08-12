import Foundation
import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var currentUser: UserProfile?
    @Published var onboardingCompleted = false
    @Published var assessmentCompleted = false
    @Published var currentPlan: Plan?
    
    // Profile caching for offline scenarios only
    @Published var profileCache: [String: UserProfile] = [:]
    private let userDefaults = UserDefaults.standard
    
    // Services
    let authService = AuthService()
    let healthKitService = HealthKitService()
    let profileService = ProfileService()
    let assessmentService = AssessmentService()
    let planService = PlanService()
    let storageService = StorageService()
    
    init() {
        Task {
            isLoading = true
            // Wait for session restoration to complete before proceeding
            let sessionRestored = await authService.restoreSession()
            if sessionRestored {
                // Only check auth status if we have a session
                await checkAuthenticationStatus()
            } else {
                // No session, user needs to sign in
                isLoading = false
            }
        }
    }
    
    private func checkAuthenticationStatus() async {
        isLoading = true
        defer { isLoading = false }
        
        // Check if user is authenticated
        if let user = authService.user {
            isAuthenticated = true
            await loadUserProfileFromDatabase(userId: user.id.uuidString)
        } else {
            isAuthenticated = false
            onboardingCompleted = false
            assessmentCompleted = false
        }
    }
    
    func updateAuthenticationStatus() async {
        await checkAuthenticationStatus()
    }
    
    // MARK: - Database-First Profile Loading
    
    /// Always check the database first for the source of truth
    private func loadUserProfileFromDatabase(userId: String) async {
        do {
            // 1. ALWAYS check database first - this is the source of truth
            let profile = try await profileService.getProfile(userId: userId)
            
            // 2. Update app state based on database data
            await MainActor.run {
                currentUser = profile
                onboardingCompleted = profile.onboardingCompleted
                // Don't set assessmentCompleted here - let the assessment service determine it
            }
            
            // 3. Check assessment completion from database
            await checkAssessmentCompletionFromDatabase(userId: userId)
            
            // 4. Cache for offline scenarios only
            profileCache[userId] = profile
            
            // 5. Update local persistence for offline fallback
            saveProfileToLocal(profile, userId: userId)
            

            
        } catch {

            
            // 6. Only fall back to local data if database is completely unavailable
            if await isDatabaseUnavailable() {
                await fallbackToLocalData(userId: userId)
            } else {
                // Database is available but profile doesn't exist - user needs to complete onboarding
                await MainActor.run {
                    currentUser = nil
                    onboardingCompleted = false
                    assessmentCompleted = false
                }

            }
        }
    }
    
    /// Check if database is completely unavailable (offline scenario)
    private func isDatabaseUnavailable() async -> Bool {
        // For now, assume database is available
        // In a production app, you might want to implement a more sophisticated connectivity check
        return false
    }
    
    /// Fallback to local data only when database is completely unavailable
    private func fallbackToLocalData(userId: String) async {

        
        if let localProfile = loadLocalProfile(userId: userId) {
            await MainActor.run {
                currentUser = localProfile
                onboardingCompleted = localProfile.onboardingCompleted
                assessmentCompleted = localProfile.assessmentCompleted
            }

        } else {
            await MainActor.run {
                currentUser = nil
                onboardingCompleted = false
                assessmentCompleted = false
            }

        }
    }
    
    // MARK: - Assessment State Management
    
    /// Always check assessment completion from database first
    private func checkAssessmentCompletionFromDatabase(userId: String) async {
        do {
            let assessments = try await assessmentService.getAssessmentHistory(profileId: userId)
            let isCompleted = !assessments.isEmpty
            
            await MainActor.run {
                assessmentCompleted = isCompleted
            }
            
            // Update local storage for offline fallback
            UserDefaults.standard.set(isCompleted, forKey: "\(userId)_assessmentCompleted")
            
            print("AppState: Assessment completion status from database: \(isCompleted)")
            
        } catch {
            print("AppState: Failed to check assessment completion from database: \(error)")
            
            // For now, just assume no assessment completed and continue
            // This prevents the app from failing to load due to RLS policy issues
            await MainActor.run {
                assessmentCompleted = false
            }
            print("AppState: Assuming no assessment completed due to database access issue")
        }
    }
    
    // MARK: - Local Data Management (Offline Fallback Only)
    
    private func loadLocalProfile(userId: String) -> UserProfile? {
        let profileDataKey = "\(userId)_profileData"
        
        // Try to load cached profile data
        if let profileData = userDefaults.data(forKey: profileDataKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
            return profile
        }
        
        return nil
    }
    
    private func saveProfileToLocal(_ profile: UserProfile, userId: String) {
        let profileDataKey = "\(userId)_profileData"
        
        // Save profile data for offline scenarios
        if let profileData = try? JSONEncoder().encode(profile) {
            userDefaults.set(profileData, forKey: profileDataKey)
        }
        
        // Save assessment status for offline scenarios
        userDefaults.set(profile.assessmentCompleted, forKey: "\(userId)_assessmentCompleted")
    }
    
    // MARK: - Sign Out and Cleanup
    
    func signOut() async {
        await authService.signOut()
        isAuthenticated = false
        currentUser = nil
        onboardingCompleted = false
        assessmentCompleted = false
        currentPlan = nil
        
        // Clear cache for this user
        if let userId = authService.user?.id.uuidString {
            profileCache.removeValue(forKey: userId)
        }
    }
    
    // MARK: - Utility Methods
    
    /// Clear all local data (useful for testing or complete reset)
    func clearAllLocalData() {
        let domain = Bundle.main.bundleIdentifier ?? "ai.mydurability.Durability"
        userDefaults.removePersistentDomain(forName: domain)
        profileCache.removeAll()
    }
    
    /// Force refresh profile from database (useful for testing)
    func forceRefreshProfile() async {
        guard let userId = authService.user?.id.uuidString else { return }
        
        // Clear cache for this user
        profileCache.removeValue(forKey: userId)
        
        // Reload from database
        await loadUserProfileFromDatabase(userId: userId)
    }
    
    /// Force refresh assessment completion status from database
    func forceRefreshAssessmentStatus() async {
        guard let userId = authService.user?.id.uuidString else { return }
        await checkAssessmentCompletionFromDatabase(userId: userId)
    }
    
    /// Clear all session data and force fresh sign-in
    func clearAllSessionData() async {
        print("AppState: Clearing all session data and forcing fresh sign-in")
        
        // Clear auth service session
        await authService.clearAllSessionData()
        
        // Reset app state
        isAuthenticated = false
        currentUser = nil
        onboardingCompleted = false
        assessmentCompleted = false
        currentPlan = nil
        
        // Clear all local data
        clearAllLocalData()
        
        print("AppState: All session data cleared, user will need to sign in again")
    }
    
    /// Get current status for debugging
    func getCurrentStatus() -> (onboardingCompleted: Bool, assessmentCompleted: Bool, hasProfile: Bool) {
        return (
            onboardingCompleted: onboardingCompleted,
            assessmentCompleted: assessmentCompleted,
            hasProfile: currentUser != nil
        )
    }
}
