import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingRetakeAlert = false
    @State private var notificationsEnabled = true
    @State private var healthKitEnabled = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Profile & Settings")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.top)
                    
                    // User Profile Card
                    UserProfileCard(user: appState.currentUser)
                    
                    // Quick Actions Card
                    QuickActionsCard(
                        profileId: appState.currentUser?.id,
                        onRetakeAssessment: { showingRetakeAlert = true }
                    )
                    
                    // Settings Card
                    SettingsCard(
                        notificationsEnabled: $notificationsEnabled,
                        healthKitEnabled: $healthKitEnabled
                    )
                    
                    // Account Card
                    AccountCard(
                        onSignOut: { Task { await appState.signOut() } }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .background(Color.darkSpaceGrey)
            .navigationBarHidden(true)
            .alert("Retake Movement Assessment", isPresented: $showingRetakeAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Start Retake", role: .destructive) {
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
        // Reset assessment completion status
        await MainActor.run {
            appState.assessmentCompleted = false
            appState.shouldShowAssessmentResults = false
            appState.currentAssessmentResults = []
        }
        
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
                }
            } catch {
                // Handle error silently
            }
        }
    }
}

// MARK: - User Profile Card
struct UserProfileCard: View {
    let user: UserProfile?
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.electricGreen)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            // User Info
            VStack(spacing: 4) {
                Text(user?.firstName ?? "User")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(appState.authService.user?.email ?? "user@example.com")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.lightSpaceGrey)
        .cornerRadius(16)
    }
}

// MARK: - Quick Actions Card
struct QuickActionsCard: View {
    let profileId: String?
    let onRetakeAssessment: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                if let profileId = profileId {
                    NavigationLink(destination: BasicInfoEditView(viewModel: ProfileEditViewModel(profileId: profileId))) {
                        QuickActionRow(
                            icon: "person.circle.fill",
                            title: "Edit Profile",
                            description: "Update your information"
                        )
                    }
                    
                    NavigationLink(destination: ProgressDashboardView()) {
                        QuickActionRow(
                            icon: "chart.bar.fill",
                            title: "View Progress",
                            description: "See your fitness journey"
                        )
                    }
                }
                
                Button(action: onRetakeAssessment) {
                    QuickActionRow(
                        icon: "arrow.clockwise",
                        title: "Re-Assess",
                        description: "Take a new movement assessment"
                    )
                }
            }
        }
        .padding(20)
        .background(Color.lightSpaceGrey)
        .cornerRadius(16)
    }
}

// MARK: - Quick Action Row
struct QuickActionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.electricGreen)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondaryText)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Settings Card
struct SettingsCard: View {
    @Binding var notificationsEnabled: Bool
    @Binding var healthKitEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                SettingToggleRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Get workout reminders",
                    isOn: $notificationsEnabled
                )
                
                SettingToggleRow(
                    icon: "heart.fill",
                    title: "HealthKit",
                    description: "Sync with Apple Health",
                    isOn: $healthKitEnabled
                )
            }
        }
        .padding(20)
        .background(Color.lightSpaceGrey)
        .cornerRadius(16)
    }
}

// MARK: - Setting Toggle Row
struct SettingToggleRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.electricGreen)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color.electricGreen))
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Account Card
struct AccountCard: View {
    let onSignOut: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                NavigationLink(destination: LegalTextView(title: "Privacy Policy")) {
                    AccountRow(
                        icon: "doc.text.fill",
                        title: "Privacy Policy",
                        description: "Read our privacy policy"
                    )
                }
                
                NavigationLink(destination: LegalTextView(title: "Terms of Service")) {
                    AccountRow(
                        icon: "doc.text.fill",
                        title: "Terms of Service",
                        description: "Read our terms of service"
                    )
                }
                
                NavigationLink(destination: LegalTextView(title: "Help & Support")) {
                    AccountRow(
                        icon: "questionmark.circle.fill",
                        title: "Help & Support",
                        description: "Get help with the app"
                    )
                }
                
                Button(action: onSignOut) {
                    AccountRow(
                        icon: "rectangle.portrait.and.arrow.right",
                        title: "Sign Out",
                        description: "Sign out of your account",
                        isDestructive: true
                    )
                }
            }
        }
        .padding(20)
        .background(Color.lightSpaceGrey)
        .cornerRadius(16)
    }
}

// MARK: - Account Row
struct AccountRow: View {
    let icon: String
    let title: String
    let description: String
    let isDestructive: Bool
    
    init(icon: String, title: String, description: String, isDestructive: Bool = false) {
        self.icon = icon
        self.title = title
        self.description = description
        self.isDestructive = isDestructive
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(isDestructive ? Color.red : Color.electricGreen)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isDestructive ? .red : .white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondaryText)
        }
        .padding(.vertical, 4)
    }
}

struct LegalTextView: View {
    let title: String
    var body: some View {
        ScrollView {
            Text("Coming soon...")
                .foregroundColor(.secondaryText)
                .padding()
        }
        .background(Color.darkSpaceGrey)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}
