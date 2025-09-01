import Foundation
import SwiftUI

@MainActor
class ProgressViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var assessmentHistory: [Assessment] = []
    @Published var latestAssessmentResult: AssessmentResult?
    @Published var assessmentResultsHistory: [AssessmentResult] = []
    @Published var workoutCompletions: [WorkoutCompletion] = []
    @Published var errorMessage: String?

    func loadProgressData(appState: AppState) {
        self.isLoading = true
        Task {
            do {
                guard let profileId = appState.currentUser?.id else {
                    errorMessage = "User profile not found."
                    isLoading = false
                    return
                }

                // Fetch assessment history
                let history = try await appState.assessmentService.getAssessmentHistory(profileId: profileId)
                self.assessmentHistory = history

                // Get results for all assessments to build progress history
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

                // Get the latest assessment and its results
                if let latestAssessment = history.first, let assessmentId = latestAssessment.assessmentId {
                    let results = try await appState.assessmentService.getAssessmentResults(assessmentId: assessmentId)
                    // We need to find the "Overall" result to display
                    self.latestAssessmentResult = results.first(where: { $0.bodyArea == "Overall" })
                }
                
                // Load workout completion data
                await loadWorkoutCompletions(appState: appState)
                
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to load progress data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Workout Completion Methods
    
    private func loadWorkoutCompletions(appState: AppState) async {
        // For now, we'll generate sample data
        // In a real app, this would come from a workout tracking service
        let calendar = Calendar.current
        let now = Date()
        let _ = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        
        var sampleCompletions: [WorkoutCompletion] = []
        
        // Generate sample data for the past month
        for dayOffset in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) {
                let shouldHaveWorkout = Bool.random() // 50% chance of having a workout
                if shouldHaveWorkout {
                    let intensity = WorkoutCompletion.WorkoutIntensity.allCases.randomElement() ?? .medium
                    let completion = WorkoutCompletion(
                        date: date,
                        completed: Bool.random(), // 80% chance of completion
                        workoutType: ["Strength", "Cardio", "Flexibility", "Balance"].randomElement(),
                        duration: TimeInterval.random(in: 1800...7200), // 30-120 minutes
                        intensity: intensity
                    )
                    sampleCompletions.append(completion)
                }
            }
        }
        
        self.workoutCompletions = sampleCompletions
    }
    
    func getDailyWorkoutStatus(for date: Date) -> DailyWorkoutStatus {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        _ = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        // Check if this is June 2025 for random data generation
        let isJune2025 = calendar.component(.year, from: date) == 2025 && 
                        calendar.component(.month, from: date) == 6
        
        if isJune2025 {
            // Generate random completion data for June 2025
            _ = calendar.component(.day, from: date)
            let weekday = calendar.component(.weekday, from: date)
            
            // Higher workout probability on weekdays (80%) vs weekends (40%)
            let isWeekend = weekday == 1 || weekday == 7 // Sunday or Saturday
            let workoutProbability = isWeekend ? 0.4 : 0.8
            
            let hasWorkout = Double.random(in: 0...1) < workoutProbability
            
            if hasWorkout {
                // Generate completion percentage based on day of week
                let baseCompletion: Double
                switch weekday {
                case 1, 7: // Weekend - lower completion
                    baseCompletion = Double.random(in: 0.3...0.7)
                case 2, 3, 4: // Early week - moderate completion
                    baseCompletion = Double.random(in: 0.5...0.8)
                case 5, 6: // Late week - higher completion
                    baseCompletion = Double.random(in: 0.6...0.9)
                default:
                    baseCompletion = Double.random(in: 0.4...0.8)
                }
                
                let workoutTypes = ["Strength", "Mobility", "Cardio"]
                let selectedTypes = workoutTypes.shuffled().prefix(Int.random(in: 1...2))
                
                return DailyWorkoutStatus(
                    date: startOfDay,
                    hasWorkout: true,
                    completionPercentage: baseCompletion,
                    workoutTypes: Array(selectedTypes)
                )
            } else {
                return DailyWorkoutStatus(
                    date: startOfDay,
                    hasWorkout: false,
                    completionPercentage: 0.0,
                    workoutTypes: []
                )
            }
        }
        
        // For other months, return no workout
        return DailyWorkoutStatus(
            date: startOfDay,
            hasWorkout: false,
            completionPercentage: 0.0,
            workoutTypes: []
        )
    }
    
    func getMonthlyWorkoutData(for date: Date) -> [DailyWorkoutStatus] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        
        var monthlyData: [DailyWorkoutStatus] = []
        
        for day in 0..<daysInMonth {
            if let dayDate = calendar.date(byAdding: .day, value: day, to: startOfMonth) {
                let status = getDailyWorkoutStatus(for: dayDate)
                monthlyData.append(status)
            }
        }
        
        return monthlyData
    }
    
    // Get chart data for automatic display (last 7 days of assessments)
    func getChartData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        // Create data points with dates
        var dataPoints: [ChartDataPoint] = []
        
        for result in assessmentResultsHistory {
            guard let assessment = assessmentHistory.first(where: { $0.assessmentId == result.assessmentId }) else {
                continue
            }
            
            // Only include assessments from the last 7 days
            if assessment.createdAt >= sevenDaysAgo {
                let dataPoint = ChartDataPoint(
                    x: 0, // Will be calculated based on position
                    y: result.durabilityScore * 100, // Convert to percentage
                    date: assessment.createdAt,
                    label: "Assessment \(String(assessment.assessmentId ?? 0).prefix(8))"
                )
                dataPoints.append(dataPoint)
            }
        }
        
        // Sort by date (oldest first for left-to-right display)
        dataPoints.sort { $0.date < $1.date }
        
        // Create final data points with correct x-axis positions
        return dataPoints.enumerated().map { index, dataPoint in
            ChartDataPoint(
                x: Double(index),
                y: dataPoint.y,
                date: dataPoint.date,
                label: dataPoint.label
            )
        }
    }
}

// MARK: - Chart Data Models
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let date: Date
    let label: String
}

