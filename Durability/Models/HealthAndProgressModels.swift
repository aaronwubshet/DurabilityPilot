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
    let id = UUID()
    let date: Date
    let completed: Bool
    let workoutType: String?
    let duration: TimeInterval?
    let intensity: WorkoutIntensity
    
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
        if completionPercentage >= 1.0 {
            return .electricGreen
        } else if completionPercentage >= 0.7 {
            return .orange
        } else if completionPercentage >= 0.4 {
            return .yellow
        } else {
            return .gray
        }
    }
}

