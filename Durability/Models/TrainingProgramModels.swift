import Foundation

// MARK: - Program Hierarchy Models

struct Program: Decodable, Identifiable {
    let id: String
    let name: String
    let slug: String?
    let weeks: Int
    let workoutsPerWeek: Int
    let version: Int?
    let createdBy: String?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date?
    
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

struct ProgramPhase: Decodable, Identifiable {
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

struct ProgramWeek: Decodable, Identifiable {
    let id: String
    let programId: String
    let weekIndex: Int
    let phaseWeekIndex: Int?
    let phaseId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case weekIndex = "week_index"
        case phaseWeekIndex = "phase_week_index"
        case phaseId = "phase_id"
    }
}

struct ProgramWorkout: Decodable, Identifiable {
    let id: String
    let programId: String
    let weekId: String
    let dayIndex: Int
    let title: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case programId = "program_id"
        case weekId = "week_id"
        case dayIndex = "day_index"
        case title
    }
}

struct MovementBlock: Decodable, Identifiable {
    let id: String
    let name: String
    let slug: String?
    let blockTypeId: Int
    let requiredEquipment: [Int]
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case slug
        case blockTypeId = "block_type_id"
        case requiredEquipment = "required_equipment"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ProgramWorkoutBlock: Decodable, Identifiable {
    let id: String
    let programWorkoutId: String
    let movementBlockId: String
    let sequence: Int
    let movementBlock: MovementBlock?
    
    enum CodingKeys: String, CodingKey {
        case id
        case programWorkoutId = "program_workout_id"
        case movementBlockId = "movement_block_id"
        case sequence
        case movementBlock = "movement_blocks"
    }
}

// Avoid conflict with existing Movement model by using a minimal type
struct MovementMinimal: Decodable, Identifiable {
    let id: String
    let name: String?
    let description: String?
}

struct MovementBlockItem: Decodable, Identifiable {
    let id: String
    let blockId: String
    let movementId: String
    let sequence: Int
    let defaultDose: [String: Any]
    let movement: MovementMinimal?
    
    enum CodingKeys: String, CodingKey {
        case id
        case blockId = "block_id"
        case movementId = "movement_id"
        case sequence
        case defaultDose = "default_dose"
        case movement = "movements"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        blockId = try container.decode(String.self, forKey: .blockId)
        movementId = try container.decode(String.self, forKey: .movementId)
        sequence = try container.decode(Int.self, forKey: .sequence)
        movement = try container.decodeIfPresent(MovementMinimal.self, forKey: .movement)
        
        // default_dose is JSONB, decode as [String: Any]
        if let nested = try? container.decode([String: String].self, forKey: .defaultDose) {
            defaultDose = nested
        } else if let data = try? container.decode(Data.self, forKey: .defaultDose),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            defaultDose = obj
        } else if let dictAny = try? container.decode([String: AnyDecodable].self, forKey: .defaultDose) {
            // Map AnyDecodable to Any
            defaultDose = dictAny.mapValues { $0.value }
        } else {
            defaultDose = [:]
        }
    }
}

// Helper to decode heterogeneous JSON values
struct AnyDecodable: Decodable {
    let value: Any
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let dictVal = try? container.decode([String: AnyDecodable].self) {
            value = dictVal.mapValues { $0.value }
        } else if let arrayVal = try? container.decode([AnyDecodable].self) {
            value = arrayVal.map { $0.value }
        } else {
            value = NSNull()
        }
    }
}

// MARK: - User Assignment & Workouts

struct UserProgram: Decodable, Identifiable {
    let id: String
    let userId: String
    let programId: String
    let programSlugSnapshot: String?
    let programNameSnapshot: String?
    let templateVersionSnapshot: Int?
    let startDate: Date
    let timezone: String?
    let status: String
    let workoutsPerWeek: Int?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date?
    let program: Program?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case programId = "program_id"
        case programSlugSnapshot = "program_slug_snapshot"
        case programNameSnapshot = "program_name_snapshot"
        case templateVersionSnapshot = "template_version_snapshot"
        case startDate = "start_date"
        case timezone
        case status
        case workoutsPerWeek = "workouts_per_week"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case program
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        programId = try container.decode(String.self, forKey: .programId)
        programSlugSnapshot = try container.decodeIfPresent(String.self, forKey: .programSlugSnapshot)
        programNameSnapshot = try container.decodeIfPresent(String.self, forKey: .programNameSnapshot)
        templateVersionSnapshot = try container.decodeIfPresent(Int.self, forKey: .templateVersionSnapshot)
        startDate = try container.decodeFlexibleDate(forKey: .startDate)
        timezone = try container.decodeIfPresent(String.self, forKey: .timezone)
        status = try container.decode(String.self, forKey: .status)
        workoutsPerWeek = try container.decodeIfPresent(Int.self, forKey: .workoutsPerWeek)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decodeFlexibleDate(forKey: .createdAt)
        updatedAt = try container.decodeFlexibleDateIfPresent(forKey: .updatedAt)
        program = try container.decodeIfPresent(Program.self, forKey: .program)
    }
}

struct UserWorkout: Decodable, Identifiable {
    let id: String
    let userProgramId: String
    let weekIndex: Int
    let dayIndex: Int
    let scheduledDate: Date
    let titleSnapshot: String
    let status: String
    let rpeSession: Double?
    let durationMinutesActual: Int?
    let userNotes: String?
    let createdAt: Date
    let updatedAt: Date?
    let userProgram: UserProgram?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userProgramId = "user_program_id"
        case weekIndex = "week_index"
        case dayIndex = "day_index"
        case scheduledDate = "scheduled_date"
        case titleSnapshot = "title_snapshot"
        case status
        case rpeSession = "rpe_session"
        case durationMinutesActual = "duration_minutes_actual"
        case userNotes = "user_notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userProgram = "user_program"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userProgramId = try container.decode(String.self, forKey: .userProgramId)
        weekIndex = try container.decode(Int.self, forKey: .weekIndex)
        dayIndex = try container.decode(Int.self, forKey: .dayIndex)
        scheduledDate = try container.decodeFlexibleDate(forKey: .scheduledDate)
        titleSnapshot = try container.decode(String.self, forKey: .titleSnapshot)
        status = try container.decode(String.self, forKey: .status)
        rpeSession = try container.decodeIfPresent(Double.self, forKey: .rpeSession)
        durationMinutesActual = try container.decodeIfPresent(Int.self, forKey: .durationMinutesActual)
        userNotes = try container.decodeIfPresent(String.self, forKey: .userNotes)
        createdAt = try container.decodeFlexibleDate(forKey: .createdAt)
        updatedAt = try container.decodeFlexibleDateIfPresent(forKey: .updatedAt)
        userProgram = try container.decodeIfPresent(UserProgram.self, forKey: .userProgram)
    }
}

private enum DateParsing {
    static let iso8601Full: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()
    
    static let iso8601NoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()
    
    static let yyyyMMdd: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    static func parse(_ value: String) -> Date? {
        if let d = iso8601Full.date(from: value) { return d }
        if let d = iso8601NoFraction.date(from: value) { return d }
        if let d = yyyyMMdd.date(from: value) { return d }
        return nil
    }
}

private extension KeyedDecodingContainer where Key: CodingKey {
    func decodeFlexibleDate(forKey key: Key) throws -> Date {
        if let dateString = try? self.decode(String.self, forKey: key) {
            if let d = DateParsing.parse(dateString) {
                return d
            } else {
                throw DecodingError.dataCorruptedError(
                    forKey: key,
                    in: self,
                    debugDescription: "Invalid date format: \(dateString)"
                )
            }
        }
        // Fallback to default Date decoding
        return try self.decode(Date.self, forKey: key)
    }
    
    func decodeFlexibleDateIfPresent(forKey key: Key) throws -> Date? {
        if let s = try self.decodeIfPresent(String.self, forKey: key) {
            return DateParsing.parse(s)
        }
        return try self.decodeIfPresent(Date.self, forKey: key)
    }
}
