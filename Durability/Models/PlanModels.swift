import Foundation

// MARK: - Movement Library
struct Movement: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let videoURL: String?
    let jointsImpacted: [String]
    let musclesImpacted: [String]
    let superMetricsImpacted: [String]
    let sportsImpacted: [String]
    let intensityOptions: [String]
    let recoveryImpactScore: Double
    let resilienceImpactScore: Double
    let resultsImpactScore: Double
}

// MARK: - Plan System

struct Intensity: Codable {
    var reps: Int?
    var sets: Int?
    var weightKg: Double?
    var distanceMeters: Double?
    var durationSeconds: Int?
    var rpe: Int? // Rate of Perceived Exertion
}

struct Plan: Codable, Identifiable {
    let id: String
    let profileId: String
    let startDate: Date
    let endDate: Date
    let createdAt: Date
    var phases: [PlanPhase]
}

struct PlanPhase: Codable, Identifiable {
    let id: String
    let planId: String
    let phaseNumber: Int
    let recoveryWeight: Double
    let resilienceWeight: Double
    let resultsWeight: Double
    let startDate: Date
    let endDate: Date
    var dailyWorkouts: [DailyWorkout]
}

struct DailyWorkout: Codable, Identifiable {
    let id: String
    let planPhaseId: String
    let workoutDate: Date
    let status: WorkoutStatus
    var movements: [DailyWorkoutMovement]
    
    enum WorkoutStatus: String, Codable {
        case pending = "pending"
        case inProgress = "in_progress"
        case completed = "completed"
    }
}

struct DailyWorkoutMovement: Codable, Identifiable {
    let id: String
    let dailyWorkoutId: String
    let movementId: Int
    let sequence: Int
    let status: MovementStatus
    let assignedIntensity: Intensity?
    let recoveryImpactScore: Double
    let resilienceImpactScore: Double
    let resultsImpactScore: Double
    
    enum MovementStatus: String, Codable {
        case pending = "pending"
        case completed = "completed"
    }
}

