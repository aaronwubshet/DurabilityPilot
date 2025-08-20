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

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case videoURL = "video_url"
        case jointsImpacted = "joints_impacted"
        case musclesImpacted = "muscles_impacted"
        case superMetricsImpacted = "super_metrics_impacted"
        case sportsImpacted = "sports_impacted"
        case intensityOptions = "intensity_options"
        case recoveryImpactScore = "recovery_impact_score"
        case resilienceImpactScore = "resilience_impact_score"
        case resultsImpactScore = "results_impact_score"
    }
}

// MARK: - Plan System

struct Intensity: Codable {
    var reps: Int?
    var sets: Int?
    var weightKg: Double?
    var distanceMeters: Double?
    var durationSeconds: Int?
    var rpe: Int? // Rate of Perceived Exertion

    enum CodingKeys: String, CodingKey {
        case reps
        case sets
        case weightKg = "weight_kg"
        case distanceMeters = "distance_meters"
        case durationSeconds = "duration_seconds"
        case rpe
    }
}

struct Plan: Codable, Identifiable {
    let id: String
    let profileId: String
    let startDate: Date
    let endDate: Date
    let createdAt: Date
    var phases: [PlanPhase] = []

    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case createdAt = "created_at"
        // phases intentionally omitted (populated client-side)
    }

    init(id: String, profileId: String, startDate: Date, endDate: Date, createdAt: Date, phases: [PlanPhase] = []) {
        self.id = id
        self.profileId = profileId
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt
        self.phases = phases
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        profileId = try container.decode(String.self, forKey: .profileId)
        startDate = try Plan.decodeFlexibleDate(container: container, key: Plan.CodingKeys.startDate)
        endDate = try Plan.decodeFlexibleDate(container: container, key: Plan.CodingKeys.endDate)
        createdAt = try Plan.decodeFlexibleDate(container: container, key: Plan.CodingKeys.createdAt)
        phases = []
    }
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
    var dailyWorkouts: [DailyWorkout] = []

    enum CodingKeys: String, CodingKey {
        case id
        case planId = "plan_id"
        case phaseNumber = "phase_number"
        case recoveryWeight = "recovery_weight"
        case resilienceWeight = "resilience_weight"
        case resultsWeight = "results_weight"
        case startDate = "start_date"
        case endDate = "end_date"
        // dailyWorkouts intentionally omitted
    }

    init(id: String, planId: String, phaseNumber: Int, recoveryWeight: Double, resilienceWeight: Double, resultsWeight: Double, startDate: Date, endDate: Date, dailyWorkouts: [DailyWorkout] = []) {
        self.id = id
        self.planId = planId
        self.phaseNumber = phaseNumber
        self.recoveryWeight = recoveryWeight
        self.resilienceWeight = resilienceWeight
        self.resultsWeight = resultsWeight
        self.startDate = startDate
        self.endDate = endDate
        self.dailyWorkouts = dailyWorkouts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        planId = try container.decode(String.self, forKey: .planId)
        phaseNumber = try container.decode(Int.self, forKey: .phaseNumber)
        recoveryWeight = try container.decode(Double.self, forKey: .recoveryWeight)
        resilienceWeight = try container.decode(Double.self, forKey: .resilienceWeight)
        resultsWeight = try container.decode(Double.self, forKey: .resultsWeight)
        startDate = try Plan.decodeFlexibleDate(container: container, key: PlanPhase.CodingKeys.startDate)
        endDate = try Plan.decodeFlexibleDate(container: container, key: PlanPhase.CodingKeys.endDate)
        dailyWorkouts = []
    }
}

struct DailyWorkout: Codable, Identifiable {
    let id: String
    let planPhaseId: String
    let workoutDate: Date
    let status: WorkoutStatus
    var movements: [DailyWorkoutMovement] = []
    
    enum WorkoutStatus: String, Codable {
        case pending = "pending"
        case inProgress = "in_progress"
        case completed = "completed"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let raw = (try? container.decode(String.self))?.lowercased() ?? "pending"
            switch raw {
            case "pending": self = .pending
            case "in_progress", "in-progress", "inprogress": self = .inProgress
            case "completed", "complete", "done": self = .completed
            default: self = .pending
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case planPhaseId = "plan_phase_id"
        case workoutDate = "workout_date"
        case status
        // movements intentionally omitted
    }

    init(id: String, planPhaseId: String, workoutDate: Date, status: WorkoutStatus, movements: [DailyWorkoutMovement] = []) {
        self.id = id
        self.planPhaseId = planPhaseId
        self.workoutDate = workoutDate
        self.status = status
        self.movements = movements
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        planPhaseId = try container.decode(String.self, forKey: .planPhaseId)
        workoutDate = try Plan.decodeFlexibleDate(container: container, key: DailyWorkout.CodingKeys.workoutDate)
        status = (try? container.decode(WorkoutStatus.self, forKey: .status)) ?? .pending
        movements = []
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
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let raw = (try? container.decode(String.self))?.lowercased() ?? "pending"
            switch raw {
            case "completed", "complete", "done": self = .completed
            default: self = .pending
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case dailyWorkoutId = "daily_workout_id"
        case movementId = "movement_id"
        case sequence
        case status
        case assignedIntensity = "assigned_intensity"
        case recoveryImpactScore = "recovery_impact_score"
        case resilienceImpactScore = "resilience_impact_score"
        case resultsImpactScore = "results_impact_score"
    }

    init(id: String, dailyWorkoutId: String, movementId: Int, sequence: Int, status: MovementStatus, assignedIntensity: Intensity?, recoveryImpactScore: Double, resilienceImpactScore: Double, resultsImpactScore: Double) {
        self.id = id
        self.dailyWorkoutId = dailyWorkoutId
        self.movementId = movementId
        self.sequence = sequence
        self.status = status
        self.assignedIntensity = assignedIntensity
        self.recoveryImpactScore = recoveryImpactScore
        self.resilienceImpactScore = resilienceImpactScore
        self.resultsImpactScore = resultsImpactScore
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        dailyWorkoutId = try container.decode(String.self, forKey: .dailyWorkoutId)
        // movementId can be int or string UUID from views; try both
        if let intId = try? container.decode(Int.self, forKey: .movementId) {
            movementId = intId
        } else if let stringId = try? container.decode(String.self, forKey: .movementId), let intFromString = Int(stringId) {
            movementId = intFromString
        } else {
            movementId = 0
        }
        sequence = (try? container.decode(Int.self, forKey: .sequence)) ?? 0
        status = (try? container.decode(MovementStatus.self, forKey: .status)) ?? .pending
        assignedIntensity = try? container.decode(Intensity.self, forKey: .assignedIntensity)
        recoveryImpactScore = (try? container.decode(Double.self, forKey: .recoveryImpactScore)) ?? 0
        resilienceImpactScore = (try? container.decode(Double.self, forKey: .resilienceImpactScore)) ?? 0
        resultsImpactScore = (try? container.decode(Double.self, forKey: .resultsImpactScore)) ?? 0
    }
}

// MARK: - Flexible Date Decoding Helper
extension Plan {
    static func decodeFlexibleDate<T: CodingKey>(container: KeyedDecodingContainer<T>, key: T) throws -> Date {
        // Try decoding as Date directly first
        if let date = try? container.decode(Date.self, forKey: key) {
            return date
        }
        // Try decoding as String then parse
        let value = try container.decode(String.self, forKey: key)
        if let iso = iso8601Formatter.date(from: value) {
            return iso
        }
        if let dateOnly = dateOnlyFormatter.date(from: value) {
            return dateOnly
        }
        // Fallback: try common ISO variants
        for fmt in isoCandidates {
            if let d = fmt.date(from: value) { return d }
        }
        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [key], debugDescription: "Unsupported date format: \(value)")
        )
    }
    static var iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    static var dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    static var isoCandidates: [DateFormatter] = {
        let fmts = [
            "yyyy-MM-dd'T'HH:mm:ssXXXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
            "yyyy-MM-dd HH:mm:ssZ"
        ]
        return fmts.map { pattern in
            let f = DateFormatter()
            f.dateFormat = pattern
            f.timeZone = TimeZone(secondsFromGMT: 0)
            f.locale = Locale(identifier: "en_US_POSIX")
            return f
        }
    }()
}

