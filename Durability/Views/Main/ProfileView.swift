import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    
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
                        NavigationLink("Equipment") { 
                            EquipmentEditView(viewModel: ProfileEditViewModel(profileId: profileId)) 
                        }
                        NavigationLink("Sports") { 
                            SportsEditView(viewModel: ProfileEditViewModel(profileId: profileId)) 
                        }
                        NavigationLink("Injuries") { 
                            InjuryHistoryEditView(viewModel: ProfileEditViewModel(profileId: profileId)) 
                        }
                        NavigationLink("Goals") { 
                            GoalsEditView(viewModel: ProfileEditViewModel(profileId: profileId)) 
                        }
                    } else {
                        Text("Profile data not available")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Assessments") {
                    NavigationLink("Retake Movement Assessment") { 
                        AssessmentFlowView() 
                    }
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
        }
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
