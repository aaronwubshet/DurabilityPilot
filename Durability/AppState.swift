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
    @Published var shouldShowAssessmentResults = false // New state to track when to show results
    @Published var currentAssessmentResults: [AssessmentResult] = [] // Store assessment results
    
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
    let networkService = NetworkService()
    
    init() {
        Task {
            isLoading = true
            // Check if user is already authenticated
            if let user = authService.user {
                isAuthenticated = true
                await loadUserProfileFromDatabase(userId: user.id.uuidString)
            } else {
                // No authenticated user - start fresh
                isAuthenticated = false
                currentUser = nil
                onboardingCompleted = false
                assessmentCompleted = false
            }
            isLoading = false
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
    
    // MARK: - Database-First Profile Loading with Network Resilience
    
    /// Always check the database first for the source of truth
    private func loadUserProfileFromDatabase(userId: String) async {
        let result = await networkService.performWithRetry {
            try await self.profileService.getProfile(userId: userId)
        }
        
        switch result {
        case .success(let profile):
            // Update app state based on database data
            await MainActor.run {
                self.currentUser = profile
                self.onboardingCompleted = profile.onboardingCompleted
            }
            
            // Check assessment completion from database
            await checkAssessmentCompletionFromDatabase(userId: userId)
            
        case .failure(let error, _, _):
            ErrorHandler.logError(error, context: "AppState.loadUserProfileFromDatabase")
            
            // No local fallback - just set to not authenticated
            await MainActor.run {
                self.isAuthenticated = false
                self.currentUser = nil
                self.onboardingCompleted = false
                self.assessmentCompleted = false
            }
            
        case .noConnection:
            // No local fallback - just set to not authenticated
            await MainActor.run {
                self.isAuthenticated = false
                self.currentUser = nil
                self.onboardingCompleted = false
                self.assessmentCompleted = false
            }
        }
    }
    
    // MARK: - Assessment State Management with Network Resilience
    
    /// Always check assessment completion from database first
    private func checkAssessmentCompletionFromDatabase(userId: String) async {
        let result = await networkService.performWithRetry {
            try await self.profileService.getProfile(userId: userId)
        }
        
        switch result {
        case .success(let profile):
            // Use the assessmentCompleted field from the database profile
            await MainActor.run {
                self.assessmentCompleted = profile.assessmentCompleted
            }
            
        case .failure(let error, _, _):
            ErrorHandler.logError(error, context: "AppState.checkAssessmentCompletionFromDatabase")
            
            // No local fallback - just assume no assessment completed
            await MainActor.run {
                self.assessmentCompleted = false
            }
            
        case .noConnection:
            await MainActor.run {
                self.assessmentCompleted = false
            }
        }
    }
    
    // MARK: - Local Data Management (Offline Fallback Only)
    
    private func loadLocalProfile(userId: String) -> UserProfile? {
        // Always return nil - no local caching
        return nil
    }
    
    private func saveProfileToLocal(_ profile: UserProfile, userId: String) {
        // Do nothing - no local persistence
    }
    
    private func clearLocalProfileData(userId: String) {
        // Do nothing - no local data to clear
    }
    
    // MARK: - Sign Out and Cleanup
    
    func signOut() async {
        await authService.signOut()
        isAuthenticated = false
        currentUser = nil
        onboardingCompleted = false
        assessmentCompleted = false
        shouldShowAssessmentResults = false
        currentPlan = nil
    }
    
    // MARK: - Utility Methods
    
    /// Clear all local data (useful for testing or complete reset)
    func clearAllLocalData() {
        let domain = Bundle.main.bundleIdentifier ?? "ai.mydurability.Durability"
        userDefaults.removePersistentDomain(forName: domain)
    }
    
    /// Force refresh profile from database (useful for testing)
    func forceRefreshProfile() async {
        guard let userId = authService.user?.id.uuidString else { return }
        
        await loadUserProfileFromDatabase(userId: userId)
    }
    
    /// Force refresh assessment completion status from database
    func forceRefreshAssessmentStatus() async {
        guard let userId = authService.user?.id.uuidString else { return }
        await checkAssessmentCompletionFromDatabase(userId: userId)
    }
    
    /// Clear all session data and force fresh sign-in
    func clearAllSessionData() async {
        // Clear auth service session
        await authService.clearAllSessionData()
        
        // Reset app state
        isAuthenticated = false
        currentUser = nil
        onboardingCompleted = false
        assessmentCompleted = false
        shouldShowAssessmentResults = false
        currentPlan = nil
        
        // Clear all local data
        clearAllLocalData()
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
