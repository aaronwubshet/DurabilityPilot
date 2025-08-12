import SwiftUI

struct AssessmentResultsView: View {
    @ObservedObject var viewModel: AssessmentViewModel
    @EnvironmentObject var appState: AppState
    @StateObject private var summaryViewModel = OnboardingSummaryViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Your Durability Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Personalized insights based on your assessment and profile")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Overall Score Card
                if let overallResult = viewModel.assessmentResults.first(where: { $0.bodyArea == "Overall" }) {
                    OverallScoreCard(score: overallResult.durabilityScore)
                }
                
                // Personal Profile Summary
                if let profile = summaryViewModel.userProfile {
                    PersonalProfileCard(profile: profile)
                }
                
                // Assessment Insights
                AssessmentInsightsCard(
                    assessmentResults: viewModel.assessmentResults,
                    userInjuries: summaryViewModel.userInjuries,
                    userGoals: summaryViewModel.userGoals,
                    userSports: summaryViewModel.userSports
                )
                
                // Training Plan Integration
                if let profile = summaryViewModel.userProfile, !profile.trainingPlanInfo.isNilOrEmpty {
                    TrainingPlanCard(trainingPlanInfo: profile.trainingPlanInfo ?? "")
                }
                
                // Equipment & Goals Alignment
                if !summaryViewModel.userEquipment.isEmpty || !summaryViewModel.userGoals.isEmpty {
                    EquipmentGoalsCard(
                        equipment: summaryViewModel.userEquipment,
                        goals: summaryViewModel.userGoals
                    )
                }
                
                // Super Metrics Breakdown
                if let overallResult = viewModel.assessmentResults.first(where: { $0.bodyArea == "Overall" }) {
                    SuperMetricsCard(overallResult: overallResult)
                }
                
                // Body Area Analysis
                BodyAreaAnalysisCard(
                    results: viewModel.assessmentResults.filter { $0.bodyArea != "Overall" },
                    userInjuries: summaryViewModel.userInjuries
                )
                
                // Action Button
                Button(action: {
                    viewModel.completeAssessment()
                    appState.assessmentCompleted = true
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate My Personalized Plan")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.top, 8)
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal)
        }
        .onAppear {
            Task {
                await summaryViewModel.loadUserData(userId: appState.authService.user?.id.uuidString ?? "")
            }
        }
    }
}

// MARK: - Overall Score Card
struct OverallScoreCard: View {
    let score: Double
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Overall Durability Score")
                .font(.headline)
                .foregroundColor(.primary)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 140, height: 140)
                
                Circle()
                    .trim(from: 0, to: score)
                    .stroke(scoreColor(score), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: score)
                
                VStack(spacing: 4) {
                    Text("\(Int(score * 100))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("out of 100")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(scoreDescription(score))
                .font(.subheadline)
                .foregroundColor(scoreColor(score))
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0.8...: return Color(red: 0.043, green: 0.847, blue: 0.0) // Electric green
        case 0.6..<0.8: return .orange
        case 0.4..<0.6: return .yellow
        default: return .red
        }
    }
    
    private func scoreDescription(_ score: Double) -> String {
        switch score {
        case 0.8...: return "Excellent durability! You're well-positioned for your goals."
        case 0.6..<0.8: return "Good foundation with room for improvement."
        case 0.4..<0.6: return "Moderate durability - targeted training will help."
        default: return "Focus on building foundational movement patterns."
        }
    }
}

// MARK: - Personal Profile Card
struct PersonalProfileCard: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.accentColor)
                Text("Your Profile")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ProfileRow(title: "Name", value: "\(profile.firstName) \(profile.lastName)")
                
                if let age = profile.age {
                    ProfileRow(title: "Age", value: "\(age) years old")
                }
                
                if let sex = profile.sex {
                    ProfileRow(title: "Sex", value: sex.displayName)
                }
                
                if let heightCm = profile.heightCm {
                    let feet = Int(heightCm / 30.48)
                    let inches = Int((heightCm.truncatingRemainder(dividingBy: 30.48)) / 2.54)
                    ProfileRow(title: "Height", value: "\(feet)'\(inches)\"")
                }
                
                if let weightKg = profile.weightKg {
                    let weightLbs = Int((weightKg * 2.20462).rounded())
                    ProfileRow(title: "Weight", value: "\(weightLbs) lbs")
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct ProfileRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Assessment Insights Card
struct AssessmentInsightsCard: View {
    let assessmentResults: [AssessmentResult]
    let userInjuries: [UserInjury]
    let userGoals: [String]
    let userSports: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.accentColor)
                Text("Personalized Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Injury-related insights
                if !userInjuries.isEmpty {
                    InsightRow(
                        icon: "exclamationmark.triangle.fill",
                        iconColor: .orange,
                        title: "Injury Considerations",
                        description: generateInjuryInsights()
                    )
                }
                
                // Goal alignment insights
                if !userGoals.isEmpty {
                    InsightRow(
                        icon: "target",
                        iconColor: .blue,
                        title: "Goal Alignment",
                        description: generateGoalInsights()
                    )
                }
                
                // Sport-specific insights
                if !userSports.isEmpty {
                    InsightRow(
                        icon: "figure.run",
                        iconColor: .green,
                        title: "Sport-Specific Analysis",
                        description: generateSportInsights()
                    )
                }
                
                // Overall assessment insights
                InsightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .purple,
                    title: "Movement Assessment",
                    description: generateAssessmentInsights()
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func generateInjuryInsights() -> String {
        let injuryNames = userInjuries.compactMap { injury in
            if let injuryId = injury.injuryId {
                // In a real app, you'd look up the injury name by ID
                return "Previous injury"
            } else {
                return injury.otherInjuryText
            }
        }.joined(separator: ", ")
        
        return "Your history with \(injuryNames) will be considered in your training plan to ensure safe progression."
    }
    
    private func generateGoalInsights() -> String {
        let goalText = userGoals.joined(separator: ", ")
        return "Your goals of \(goalText) align well with your current durability profile. We'll focus on areas that support these objectives."
    }
    
    private func generateSportInsights() -> String {
        let sportText = userSports.joined(separator: ", ")
        return "Your participation in \(sportText) requires specific movement patterns. Your assessment shows areas we can optimize for these activities."
    }
    
    private func generateAssessmentInsights() -> String {
        let lowestArea = assessmentResults
            .filter { $0.bodyArea != "Overall" }
            .min { $0.durabilityScore < $1.durabilityScore }
        
        if let lowest = lowestArea {
            return "Your \(lowest.bodyArea.lowercased()) shows the most opportunity for improvement. We'll prioritize this area in your training."
        }
        
        return "Your movement assessment reveals a balanced profile with good overall durability."
    }
}

struct InsightRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - Training Plan Card
struct TrainingPlanCard: View {
    let trainingPlanInfo: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.accentColor)
                Text("Current Training Plan")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Text(trainingPlanInfo)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("Your personalized plan will integrate with your current training approach.")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Equipment & Goals Card
struct EquipmentGoalsCard: View {
    let equipment: [String]
    let goals: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.accentColor)
                Text("Equipment & Goals")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                if !equipment.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Available Equipment")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(equipment.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !goals.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fitness Goals")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(goals.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Super Metrics Card
struct SuperMetricsCard: View {
    let overallResult: AssessmentResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.accentColor)
                Text("Super Metrics Breakdown")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                MetricRow(name: "Range of Motion", score: overallResult.rangeOfMotionScore)
                MetricRow(name: "Flexibility", score: overallResult.flexibilityScore)
                MetricRow(name: "Mobility", score: overallResult.mobilityScore)
                MetricRow(name: "Functional Strength", score: overallResult.functionalStrengthScore)
                MetricRow(name: "Aerobic Capacity", score: overallResult.aerobicCapacityScore)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct MetricRow: View {
    let name: String
    let score: Double
    
    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
            
            Spacer()
            
            HStack(spacing: 8) {
                ProgressView(value: score)
                    .progressViewStyle(LinearProgressViewStyle(tint: scoreColor(score)))
                    .frame(width: 60)
                
                Text("\(Int(score * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(scoreColor(score))
                    .frame(width: 35, alignment: .trailing)
            }
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0.8...: return Color(red: 0.043, green: 0.847, blue: 0.0) // Electric green
        case 0.6..<0.8: return .orange
        case 0.4..<0.6: return .yellow
        default: return .red
        }
    }
}

// MARK: - Body Area Analysis Card
struct BodyAreaAnalysisCard: View {
    let results: [AssessmentResult]
    let userInjuries: [UserInjury]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.stand")
                    .foregroundColor(.accentColor)
                Text("Body Area Analysis")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(results) { result in
                    BodyAreaCard(result: result, hasInjury: hasInjuryForBodyArea(result.bodyArea))
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func hasInjuryForBodyArea(_ bodyArea: String) -> Bool {
        // In a real app, you'd map injuries to body areas
        // For now, just check if there are any injuries
        return !userInjuries.isEmpty
    }
}

struct BodyAreaCard: View {
    let result: AssessmentResult
    let hasInjury: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(result.bodyArea)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if hasInjury {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption2)
                }
            }
            
            Text("\(Int(result.durabilityScore * 100))%")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(scoreColor(result.durabilityScore))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0.8...: return Color(red: 0.043, green: 0.847, blue: 0.0) // Electric green
        case 0.6..<0.8: return .orange
        case 0.4..<0.6: return .yellow
        default: return .red
        }
    }
}

// MARK: - Onboarding Summary ViewModel
@MainActor
class OnboardingSummaryViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var userEquipment: [String] = []
    @Published var userInjuries: [UserInjury] = []
    @Published var userSports: [String] = []
    @Published var userGoals: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let profileService = ProfileService()
    
    func loadUserData(userId: String) async {
        guard !userId.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Load user profile
            userProfile = try await profileService.getProfile(userId: userId)
            
            // Load user selections
            let equipmentIds = try await profileService.getUserEquipment(profileId: userId)
            let injuryData = try await profileService.getUserInjuries(profileId: userId)
            let sportIds = try await profileService.getUserSports(profileId: userId)
            let goalIds = try await profileService.getUserGoals(profileId: userId)
            
            // Convert IDs to names (in a real app, you'd have reference data)
            userEquipment = equipmentIds.map { "Equipment \($0)" }
            userInjuries = injuryData
            userSports = sportIds.map { "Sport \($0)" }
            userGoals = goalIds.map { "Goal \($0)" }
            
        } catch {
            errorMessage = "Failed to load user data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// MARK: - Extensions
extension String {
    var isNilOrEmpty: Bool {
        return self.isEmpty || self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    AssessmentResultsView(viewModel: AssessmentViewModel())
        .environmentObject(AppState())
}
