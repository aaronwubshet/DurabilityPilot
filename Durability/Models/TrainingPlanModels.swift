import Foundation

// MARK: - Training Program Models (Matching Database Schema)

struct Program: Codable, Identifiable {
    let id: String
    let name: String
    let slug: String?
    let weeks: Int
    let workoutsPerWeek: Int
    let version: Int
    let createdBy: String?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case slug
        case weeks
        case workoutsPerWeek = "workouts_per_week"
        case version
        case createdBy = "created_by"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ProgramPhase: Codable, Identifiable {
    let id: String
    let programId: String
    let phaseIndex: Int
    let weeksCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case phaseIndex = "phase_index"
        case weeksCount = "weeks_count"
    }
}

struct ProgramWeek: Codable, Identifiable {
    let id: String
    let programId: String
    let phaseId: String
    let weekIndex: Int
    let phaseWeekIndex: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case phaseId = "phase_id"
        case weekIndex = "week_index"
        case phaseWeekIndex = "phase_week_index"
    }
}

struct ProgramWorkout: Codable, Identifiable {
    let id: String
    let programId: String
    let weekId: String
    let dayIndex: Int
    let title: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case weekId = "week_id"
        case dayIndex = "day_index"
        case title
    }
}

struct ProgramWorkoutBlock: Codable, Identifiable {
    let id: String
    let programWorkoutId: String
    let sequence: Int
    let movementBlockId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case programWorkoutId = "program_workout_id"
        case sequence
        case movementBlockId = "movement_block_id"
    }
}

struct MovementBlock: Codable, Identifiable {
    let id: String
    let name: String
    let createdAt: Date?
    let blockTypeId: Int
    let slug: String?
    let requiredEquipment: [String]
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt = "created_at"
        case blockTypeId = "block_type_id"
        case slug
        case requiredEquipment = "required_equipment"
        case updatedAt = "updated_at"
    }
}

struct MovementBlockItem: Codable, Identifiable {
    let id: String
    let blockId: String
    let sequence: Int
    let movementId: String
    let defaultDose: String // Store as JSON string
    
    enum CodingKeys: String, CodingKey {
        case id
        case blockId = "block_id"
        case sequence
        case movementId = "movement_id"
        case defaultDose = "default_dose"
    }
    
    // Computed property to get parsed dose data
    var doseData: [String: Any] {
        if let data = defaultDose.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return json
        }
        return [:]
    }
    
    init(id: String, blockId: String, sequence: Int, movementId: String, defaultDose: String) {
        self.id = id
        self.blockId = blockId
        self.sequence = sequence
        self.movementId = movementId
        self.defaultDose = defaultDose
    }
}

// MARK: - User Progress Tracking Models

struct UserWorkout: Codable, Identifiable {
    let id: String
    let userId: String
    let workoutId: String
    let startedAt: Date
    let completedAt: Date?
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case workoutId = "workout_id"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case status
    }
}

struct UserWorkoutBlock: Codable, Identifiable {
    let id: String
    let workoutSessionId: String
    let blockId: String
    let startedAt: Date?
    let completedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case workoutSessionId = "workout_session_id"
        case blockId = "block_id"
        case startedAt = "started_at"
        case completedAt = "completed_at"
    }
}

struct UserSetLog: Codable, Identifiable {
    let id: String
    let workoutSessionId: String
    let blockItemId: String
    let reps: Int
    let weight: Double?
    let notes: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case workoutSessionId = "workout_session_id"
        case blockItemId = "block_item_id"
        case reps
        case weight
        case notes
        case createdAt = "created_at"
    }
}

// MARK: - Block Type Enum

enum BlockType: Int, CaseIterable {
    case warmUp = 1
    case strengthConditioning = 2
    case aerobic = 3
    case coolDown = 4
    
    var displayName: String {
        switch self {
        case .warmUp:
            return "Warm-Up"
        case .strengthConditioning:
            return "Strength & Conditioning"
        case .aerobic:
            return "Aerobic"
        case .coolDown:
            return "Cool-Down"
        }
    }
}

// MARK: - Workout Status Enum

enum WorkoutStatus: String, CaseIterable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
    case skipped = "skipped"
    
    var displayName: String {
        switch self {
        case .notStarted:
            return "Not Started"
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        case .skipped:
            return "Skipped"
        }
    }
}
