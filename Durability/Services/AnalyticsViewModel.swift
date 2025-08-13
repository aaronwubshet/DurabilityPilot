import Foundation
import SwiftUI

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var latestAssessmentResult: AssessmentResult?
    @Published var assessmentResultsHistory: [AssessmentResult] = []
    @Published var insights: [Insight] = []
    @Published var recommendations: [Recommendation] = []
    @Published var errorMessage: String?

    func loadAnalyticsData(appState: AppState) {
        self.isLoading = true
        Task {
            do {
                guard let profileId = appState.currentUser?.id else {
                    errorMessage = "User profile not found."
                    isLoading = false
                    return
                }

                // Fetch assessment history and results
                let history = try await appState.assessmentService.getAssessmentHistory(profileId: profileId)
                
                // Get results for all assessments
                var allResults: [AssessmentResult] = []
                for assessment in history {
                    if let assessmentId = assessment.assessmentId {
                        let results = try await appState.assessmentService.getAssessmentResults(assessmentId: assessmentId)
                        if let overallResult = results.first(where: { $0.bodyArea == "Overall" }) {
                            allResults.append(overallResult)
                        }
                    }
                }
                self.assessmentResultsHistory = allResults

                // Get the latest assessment result
                if let latestAssessment = history.first, let assessmentId = latestAssessment.assessmentId {
                    let results = try await appState.assessmentService.getAssessmentResults(assessmentId: assessmentId)
                    self.latestAssessmentResult = results.first(where: { $0.bodyArea == "Overall" })
                }
                
                // Generate insights and recommendations
                generateInsights()
                generateRecommendations()
                
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to load analytics data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // Get chart data for a specific metric
    func getChartData(for metric: AnalyticsMetric) -> [ChartDataPoint] {
        guard !assessmentResultsHistory.isEmpty else { return [] }
        
        return assessmentResultsHistory.enumerated().map { index, result in
            let value = getMetricValue(result: result, metric: metric)
            return ChartDataPoint(
                x: Double(index),
                y: value * 100, // Convert to percentage
                date: Date(), // We could add actual dates here
                label: "Assessment \(index + 1)"
            )
        }.sorted { $0.date < $1.date }
    }
    
    private func getMetricValue(result: AssessmentResult, metric: AnalyticsMetric) -> Double {
        switch metric {
        case .durabilityScore:
            return result.durabilityScore
        case .rangeOfMotion:
            return result.rangeOfMotionScore
        case .flexibility:
            return result.flexibilityScore
        case .mobility:
            return result.mobilityScore
        case .functionalStrength:
            return result.functionalStrengthScore
        case .aerobicCapacity:
            return result.aerobicCapacityScore
        }
    }
    
    // Generate insights based on assessment data
    private func generateInsights() {
        guard let latestResult = latestAssessmentResult else {
            insights = []
            return
        }
        
        var newInsights: [Insight] = []
        
        // Range of Motion insight
        if latestResult.rangeOfMotionScore > 0.75 {
            newInsights.append(Insight(
                title: "Improving Range of Motion",
                description: "Your shoulder mobility has increased by 12% this month. Keep up the great work!",
                iconName: "arrow.up.circle.fill",
                color: .electricGreen
            ))
        }
        
        // Flexibility insight
        if latestResult.flexibilityScore < 0.6 {
            newInsights.append(Insight(
                title: "Recovery Focus Needed",
                description: "Your flexibility score has decreased slightly. Consider adding more stretching to your routine.",
                iconName: "exclamationmark.triangle.fill",
                color: .yellow
            ))
        }
        
        // Consistency insight
        if assessmentResultsHistory.count >= 3 {
            newInsights.append(Insight(
                title: "Consistency Achievement",
                description: "You've completed 85% of your planned workouts this month. Excellent consistency!",
                iconName: "checkmark.circle.fill",
                color: .electricGreen
            ))
        }
        
        // Overall progress insight
        if let previousResult = assessmentResultsHistory.dropFirst().first {
            let improvement = latestResult.durabilityScore - previousResult.durabilityScore
            if improvement > 0.05 {
                newInsights.append(Insight(
                    title: "Overall Progress",
                    description: "Your overall durability score has improved by \(Int(improvement * 100))% since your last assessment!",
                    iconName: "chart.line.uptrend.xyaxis",
                    color: .electricGreen
                ))
            }
        }
        
        insights = newInsights
    }
    
    // Generate recommendations based on assessment data
    private func generateRecommendations() {
        guard let latestResult = latestAssessmentResult else {
            recommendations = []
            return
        }
        
        var newRecommendations: [Recommendation] = []
        
        // Mobility recommendation
        if latestResult.mobilityScore < 0.7 {
            newRecommendations.append(Recommendation(
                title: "Add Mobility Work",
                description: "Your thoracic mobility could improve. Try adding 10 minutes of thoracic extension exercises.",
                iconName: "figure.flexibility",
                color: .orange,
                severity: .medium
            ))
        }
        
        // Recovery recommendation
        if latestResult.flexibilityScore < 0.6 {
            newRecommendations.append(Recommendation(
                title: "Increase Recovery Sessions",
                description: "Your recovery metrics suggest you could benefit from more active recovery sessions.",
                iconName: "heart.fill",
                color: .red,
                severity: .high
            ))
        }
        
        // Strength recommendation
        if latestResult.functionalStrengthScore > 0.8 {
            newRecommendations.append(Recommendation(
                title: "Progressive Overload",
                description: "Your strength metrics are plateauing. Consider increasing resistance in your workouts.",
                iconName: "dumbbell.fill",
                color: .orange,
                severity: .medium
            ))
        }
        
        // Aerobic capacity recommendation
        if latestResult.aerobicCapacityScore < 0.65 {
            newRecommendations.append(Recommendation(
                title: "Cardio Focus",
                description: "Your aerobic capacity needs attention. Add 20 minutes of cardio 3 times per week.",
                iconName: "figure.run",
                color: .red,
                severity: .high
            ))
        }
        
        // Balance recommendation
        if latestResult.rangeOfMotionScore < 0.6 && latestResult.flexibilityScore < 0.6 {
            newRecommendations.append(Recommendation(
                title: "Balance Training",
                description: "Both range of motion and flexibility need work. Focus on dynamic stretching and mobility drills.",
                iconName: "figure.mixed.cardio",
                color: .orange,
                severity: .medium
            ))
        }
        
        recommendations = newRecommendations
    }
}
