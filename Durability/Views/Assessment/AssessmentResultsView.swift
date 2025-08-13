import SwiftUI

struct AssessmentResultsView: View {
    @ObservedObject var viewModel: AssessmentViewModel
    @EnvironmentObject var appState: AppState
    @StateObject private var summaryViewModel = OnboardingSummaryViewModel()
    
    // Allow passing assessment results directly
    let assessmentResults: [AssessmentResult]
    let isViewOnly: Bool
    
    init(viewModel: AssessmentViewModel, assessmentResults: [AssessmentResult] = [], isViewOnly: Bool = false) {
        self.viewModel = viewModel
        self.assessmentResults = assessmentResults.isEmpty ? viewModel.assessmentResults : assessmentResults
        self.isViewOnly = isViewOnly
    }
    
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
                if let overallResult = assessmentResults.first(where: { $0.bodyArea == "Overall" }) {
                    OverallScoreCard(score: overallResult.durabilityScore)
                }
                
                // Personal Profile Summary
                if let profile = summaryViewModel.userProfile {
                    PersonalProfileCard(profile: profile)
                }
                
                // Assessment Insights
                AssessmentInsightsCard(
                    assessmentResults: assessmentResults,
                    userInjuries: summaryViewModel.userInjuries,
                    userGoals: summaryViewModel.userGoals,
                    userSports: summaryViewModel.userSports
                )
                
                // Training Plan Integration
                TrainingPlanCard(trainingPlanInfo: summaryViewModel.getTrainingPlanInfo(profile: summaryViewModel.userProfile))
                
                // Equipment & Goals Alignment
                EquipmentGoalsCard(
                    equipment: summaryViewModel.userEquipment,
                    goals: summaryViewModel.userGoals
                )
                
                // Super Metrics Breakdown
                if let overallResult = viewModel.assessmentResults.first(where: { $0.bodyArea == "Overall" }) {
                    SuperMetricsCard(overallResult: overallResult)
                }
                
                // Body Area Analysis
                BodyAreaAnalysisCard(
                    results: viewModel.assessmentResults.filter { $0.bodyArea != "Overall" },
                    userInjuries: summaryViewModel.userInjuries,
                    fallbackResults: summaryViewModel.getDefaultBodyAreaResults()
                )
                
                // Action Buttons - Only show if not in view-only mode
                if !isViewOnly {
                    VStack(spacing: 12) {
                        if !appState.assessmentCompleted {
                            // First time completion - only show "Generate My Personalized Plan"
                            Button(action: {
                                viewModel.completeAssessment(appState: appState)
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
                        } else {
                            // Retake scenario - show "Start New Assessment" and "Go to Main App"
                            Button(action: {
                                // Start a new assessment by resetting the view model state
                                viewModel.resetForNewAssessment()
                                // Set app flow state to start re-assessment
                                appState.appFlowState = .assessment
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Start New Assessment")
                                }
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                // Mark assessment as completed and go to main app
                                Task {
                                    guard appState.authService.user?.id.uuidString != nil else { return }
                                    
                                    do {
                                        // Update user profile to mark assessment as completed
                                        var updatedProfile = appState.currentUser
                                        updatedProfile?.assessmentCompleted = true
                                        updatedProfile?.updatedAt = Date()
                                        
                                        if let profile = updatedProfile {
                                            try await appState.profileService.updateProfile(profile)
                                            
                                            // Update app state to move to main app
                                            await MainActor.run {
                                                appState.currentUser = profile
                                                appState.appFlowState = .mainApp
                                            }
                                        }
                                    } catch {
                                        // Handle error if needed
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "house.fill")
                                    Text("Go to Main App")
                                }
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.electricGreen)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                
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
            if injury.injuryId != nil {
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
    let fallbackResults: [AssessmentResult]
    
    private var displayResults: [AssessmentResult] {
        return results.isEmpty ? fallbackResults : results
    }
    
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
            
            if results.isEmpty {
                Text("Sample body area analysis based on common assessment patterns")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(displayResults, id: \.identifier) { result in
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
            
            // Convert IDs to names with hardcoded mappings for consistent display
            userEquipment = equipmentIds.isEmpty ? getDefaultEquipment() : mapEquipmentIds(equipmentIds)
            userInjuries = injuryData.isEmpty ? getDefaultInjuries() : injuryData
            userSports = sportIds.isEmpty ? getDefaultSports() : mapSportIds(sportIds)
            userGoals = goalIds.isEmpty ? getDefaultGoals() : mapGoalIds(goalIds)
            
        } catch {
            errorMessage = "Failed to load user data: \(error.localizedDescription)"
            // Set default values if loading fails
            userEquipment = getDefaultEquipment()
            userInjuries = getDefaultInjuries()
            userSports = getDefaultSports()
            userGoals = getDefaultGoals()
        }
        
        isLoading = false
    }
    
    // MARK: - Hardcoded Mappings
    
    private func mapEquipmentIds(_ ids: [Int]) -> [String] {
        let equipmentMap: [Int: String] = [
            1: "Dumbbells",
            2: "Resistance Bands",
            3: "Yoga Mat",
            4: "Foam Roller",
            5: "Pull-up Bar",
            6: "Kettlebell",
            7: "Medicine Ball",
            8: "Stability Ball",
            9: "TRX System",
            10: "Barbell & Plates"
        ]
        
        return ids.compactMap { equipmentMap[$0] ?? "Equipment \($0)" }
    }
    
    private func mapSportIds(_ ids: [Int]) -> [String] {
        let sportMap: [Int: String] = [
            1: "Running",
            2: "Weightlifting",
            3: "Yoga",
            4: "CrossFit",
            5: "Swimming",
            6: "Cycling",
            7: "Basketball",
            8: "Soccer",
            9: "Tennis",
            10: "Golf",
            11: "Rock Climbing",
            12: "Martial Arts"
        ]
        
        return ids.compactMap { sportMap[$0] ?? "Sport \($0)" }
    }
    
    private func mapGoalIds(_ ids: [Int]) -> [String] {
        let goalMap: [Int: String] = [
            1: "Build Strength",
            2: "Improve Flexibility",
            3: "Increase Endurance",
            4: "Lose Weight",
            5: "Gain Muscle",
            6: "Improve Mobility",
            7: "Rehabilitate Injury",
            8: "Enhance Athletic Performance",
            9: "Maintain Fitness",
            10: "Reduce Pain"
        ]
        
        return ids.compactMap { goalMap[$0] ?? "Goal \($0)" }
    }
    
    private func getDefaultEquipment() -> [String] {
        return ["Basic Home Equipment", "Bodyweight Exercises"]
    }
    
    private func getDefaultInjuries() -> [UserInjury] {
        return [
            UserInjury(
                profileId: "default",
                injuryId: nil,
                otherInjuryText: "No significant injury history",
                isActive: false,
                reportedAt: Date()
            )
        ]
    }
    
    private func getDefaultSports() -> [String] {
        return ["General Fitness", "Daily Activities"]
    }
    
    private func getDefaultGoals() -> [String] {
        return ["Improve Overall Health", "Enhance Movement Quality"]
    }
    
    func getTrainingPlanInfo(profile: UserProfile?) -> String {
        if let profile = profile, 
           let trainingPlanInfo = profile.trainingPlanInfo, 
           !trainingPlanInfo.isNilOrEmpty {
            return trainingPlanInfo
        }
        
        // Default training plan info based on common scenarios
        return "Your personalized training plan will be designed based on your assessment results, focusing on improving your weakest areas while building on your strengths. The plan will include mobility work, strength training, and movement patterns tailored to your specific needs."
    }
    
    func getDefaultBodyAreaResults() -> [AssessmentResult] {
        let defaultBodyAreas = ["Shoulder", "Torso", "Hips", "Knees", "Ankles", "Elbows"]
        let defaultScores: [String: Double] = [
            "Shoulder": 0.75,
            "Torso": 0.82,
            "Hips": 0.68,
            "Knees": 0.71,
            "Ankles": 0.79,
            "Elbows": 0.73
        ]
        
        return defaultBodyAreas.map { bodyArea in
            AssessmentResult(
                id: nil,
                assessmentId: 1,
                profileId: "default",
                bodyArea: bodyArea,
                durabilityScore: defaultScores[bodyArea] ?? 0.7,
                rangeOfMotionScore: Double.random(in: 0.6...0.9),
                flexibilityScore: Double.random(in: 0.5...0.8),
                functionalStrengthScore: Double.random(in: 0.6...0.9),
                mobilityScore: Double.random(in: 0.5...0.8),
                aerobicCapacityScore: Double.random(in: 0.7...0.9)
            )
        }
    }
}

// MARK: - Extensions
extension String {
    var isNilOrEmpty: Bool {
        return self.isEmpty || self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    AssessmentResultsView(viewModel: AssessmentViewModel(), assessmentResults: [])
        .environmentObject(AppState())
}
