import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingRetakeAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Integrations") {
                    NavigationLink("Apple Health") { 
                        HealthKitView(viewModel: OnboardingViewModel()) 
                    }
                }
                
                Section("Profile") {
                    if let profileId = appState.currentUser?.id {
                        NavigationLink("Edit Basic Info") { 
                            BasicInfoEditView(viewModel: ProfileEditViewModel(profileId: profileId)) 
                        }
                        NavigationLink("Training Plan") { 
                            TrainingPlanEditView(viewModel: ProfileEditViewModel(profileId: profileId)) 
                        }
                        NavigationLink("Sports") { 
                            SportsEditView(viewModel: ProfileEditViewModel(profileId: profileId)) 
                        }
                    } else {
                        Text("Profile data not available")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Assessments") {
                    Button("Retake Movement Assessment") {
                        showingRetakeAlert = true
                    }
                    .foregroundColor(.blue)
                }
                
                Section("Account") {
                    Button(role: .destructive) {
                        Task { await appState.signOut() }
                    } label: {
                        Text("Sign Out")
                    }
                }
                
                Section("Legal") {
                    NavigationLink("Terms and Conditions") { 
                        LegalTextView(title: "Terms and Conditions") 
                    }
                    NavigationLink("Privacy Policy") { 
                        LegalTextView(title: "Privacy Policy") 
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Retake Movement Assessment", isPresented: $showingRetakeAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Start Retake", role: .destructive) {
                    print("🔍 ProfileView - User confirmed retake assessment")
                    print("   - This will create new assessment record and results with full logging")
                    
                    // Reset app state to allow fresh assessment
                    Task {
                        await resetForRetake()
                    }
                }
            } message: {
                Text("This will start a new movement assessment. Your previous assessment results will be preserved, but you'll need to complete the full assessment again.")
            }
        }
    }
    
    /// Reset app state to allow a fresh assessment retake
    private func resetForRetake() async {
        print("🔍 ProfileView.resetForRetake() - Starting")
        
        // Reset assessment completion status
        await MainActor.run {
            appState.assessmentCompleted = false
            appState.shouldShowAssessmentResults = false
            appState.currentAssessmentResults = []
        }
        
        print("🔍 ProfileView.resetForRetake() - Reset app state:")
        print("   - assessmentCompleted: \(appState.assessmentCompleted)")
        print("   - shouldShowAssessmentResults: \(appState.shouldShowAssessmentResults)")
        print("   - currentAssessmentResults count: \(appState.currentAssessmentResults.count)")
        
        // Update the user profile in the database to mark assessment as not completed
        if appState.authService.user?.id != nil {
            do {
                var updatedProfile = appState.currentUser
                updatedProfile?.assessmentCompleted = false
                updatedProfile?.updatedAt = Date()
                
                if let profile = updatedProfile {
                    try await appState.profileService.updateProfile(profile)
                    
                    await MainActor.run {
                        appState.currentUser = profile
                    }
                    
                    print("✅ ProfileView.resetForRetake() - Updated profile in database")
                }
            } catch {
                print("❌ ProfileView.resetForRetake() - Failed to update profile: \(error)")
            }
        }
        
        print("✅ ProfileView.resetForRetake() - Ready for fresh assessment")
    }
}

struct LegalTextView: View {
    let title: String
    var body: some View {
        ScrollView {
            Text("Coming soon...")
                .foregroundColor(.secondary)
                .padding()
        }
        .navigationTitle(title)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}
