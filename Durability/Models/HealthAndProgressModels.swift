import Foundation
import SwiftUI

// MARK: - Health Data
struct HealthData: Codable {
    let steps: Int
    let activeEnergy: Double
    let heartRate: Double?
    let weight: Double?
    let height: Double?
    let date: Date
}

// MARK: - Workout Completion Models
struct WorkoutCompletion: Codable, Identifiable {
    let id: UUID
    let date: Date
    let completed: Bool
    let workoutType: String?
    let duration: TimeInterval?
    let intensity: WorkoutIntensity
    
    init(date: Date, completed: Bool, workoutType: String?, duration: TimeInterval?, intensity: WorkoutIntensity) {
        self.id = UUID()
        self.date = date
        self.completed = completed
        self.workoutType = workoutType
        self.duration = duration
        self.intensity = intensity
    }
    
    enum WorkoutIntensity: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .green
            case .high: return .red
            }
        }
    }
}

struct DailyWorkoutStatus {
    let date: Date
    let hasWorkout: Bool
    let completionPercentage: Double // 0.0 to 1.0
    let workoutTypes: [String]
    
    var ringColor: Color {
        if completionPercentage >= 0.8 {
            return .green // 80-100%
        } else if completionPercentage >= 0.6 {
            return .yellow // 60-80%
        } else if completionPercentage >= 0.4 {
            return .orange // 40-60%
        } else if completionPercentage > 0.0 {
            return .red // <40%
        } else {
            return .gray // No workout
        }
    }
}

