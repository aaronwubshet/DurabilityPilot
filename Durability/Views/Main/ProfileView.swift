import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showingRetakeAlert = false
    @State private var showingLatestResults = false
    @State private var notificationsEnabled = true
    @State private var healthKitEnabled = true
    @State private var latestAssessmentResults: [AssessmentResult] = []
    @State private var isLoadingResults = false
    
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
                        onRetakeAssessment: { showingRetakeAlert = true },
                        onViewLatestResults: { 
                            Task {
                                await loadLatestAssessmentResults()
                                showingLatestResults = true
                            }
                        }
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.electricGreen)
                }
            }
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
            .sheet(isPresented: $showingLatestResults) {
                AssessmentResultsView(
                    viewModel: AssessmentViewModel(),
                    assessmentResults: latestAssessmentResults,
                    isViewOnly: true
                )
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") {
                            showingLatestResults = false
                        }
                        .foregroundColor(.electricGreen)
                    }
                }
            }
        }
    }
    
    /// Reset app state to allow a fresh assessment retake
    private func resetForRetake() async {
        // Set app flow state to start re-assessment
        await MainActor.run {
            appState.appFlowState = .assessment
            appState.currentAssessmentResults = []
        }
        
        // Note: We do NOT update assessment_completed to false in the database
        // because this flag should only be set to true once the user has completed
        // their first assessment, and should never be reset to false
    }
    
    /// Load the latest assessment results from the database
    private func loadLatestAssessmentResults() async {
        await MainActor.run {
            isLoadingResults = true
        }
        
        guard let userId = appState.authService.user?.id.uuidString else {
            await MainActor.run {
                isLoadingResults = false
            }
            return
        }
        
        do {
            // Get the latest assessment
            let latestAssessment = try await appState.assessmentService.getLatestAssessment(profileId: userId)
            
            guard let assessment = latestAssessment, let assessmentId = assessment.assessmentId else {
                await MainActor.run {
                    latestAssessmentResults = []
                    isLoadingResults = false
                }
                return
            }
            
            // Get the results for this assessment
            let results = try await appState.assessmentService.getAssessmentResults(assessmentId: assessmentId)
            
            await MainActor.run {
                latestAssessmentResults = results
                isLoadingResults = false
            }
            
        } catch {
            await MainActor.run {
                latestAssessmentResults = []
                isLoadingResults = false
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
    let onViewLatestResults: () -> Void
    
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
                    
                    // Removed navigation to ProgressDashboardView since it's accessible via tab bar
                    // and ProfileView is now presented as a sheet
                }
                
                Button(action: onRetakeAssessment) {
                    QuickActionRow(
                        icon: "arrow.clockwise",
                        title: "Re-Assess",
                        description: "Take a new movement assessment"
                    )
                }
                
                Button(action: onViewLatestResults) {
                    QuickActionRow(
                        icon: "chart.bar.fill",
                        title: "View Latest Results",
                        description: "See your recent assessment summary"
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
                Link(destination: URL(string: "https://www.mydurability.ai/privacy-policy.html")!) {
                    AccountRow(
                        icon: "doc.text.fill",
                        title: "Privacy Policy",
                        description: "Read our privacy policy"
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Link(destination: URL(string: "https://www.mydurability.ai/terms.html")!) {
                    AccountRow(
                        icon: "doc.text.fill",
                        title: "Terms of Service",
                        description: "Read our terms of service"
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: FeedbackFormView()) {
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
