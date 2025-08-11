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
    
    // Services
    let authService = AuthService()
    let healthKitService = HealthKitService()
    let profileService = ProfileService()
    let assessmentService = AssessmentService()
    let planService = PlanService()
    let storageService = StorageService()
    
    init() {
        // Check authentication status on app launch
        Task {
            isLoading = true
            // First, ask auth service to restore any persisted session
            await authService.restoreSession()
            // Then proceed with our normal routing logic
            await checkAuthenticationStatus()
        }
    }
    
    private func checkAuthenticationStatus() async {
        isLoading = true
        defer { isLoading = false }
        
        // Check if user is authenticated
        if let user = authService.user {
            isAuthenticated = true
            await loadUserProfile(userId: user.id.uuidString)
        } else {
            isAuthenticated = false
            onboardingCompleted = false
            assessmentCompleted = false
        }
    }
    
    func updateAuthenticationStatus() async {
        await checkAuthenticationStatus()
    }
    
    private func loadUserProfile(userId: String) async {
        do {
            currentUser = try await profileService.getProfile(userId: userId)
            // If a profile exists in Supabase, treat onboarding as completed (returning user)
            onboardingCompleted = true
            assessmentCompleted = currentUser?.assessmentCompleted ?? false
        } catch {
            print("Error loading user profile: \(error)")
            // If profile doesn't exist, user is new and needs onboarding
            onboardingCompleted = false
            assessmentCompleted = false
        }
    }
    
    func signOut() async {
        await authService.signOut()
        isAuthenticated = false
        currentUser = nil
        onboardingCompleted = false
        assessmentCompleted = false
        currentPlan = nil
    }
}
