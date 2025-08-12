import Foundation

// MARK: - Equipment
struct Equipment: Codable, Identifiable {
    let id: Int
    let name: String
}

// MARK: - Injury
struct Injury: Codable, Identifiable {
    let id: Int
    let name: String
}

// MARK: - Sport
struct Sport: Codable, Identifiable {
    let id: Int
    let name: String
}

// MARK: - Goal
struct Goal: Codable, Identifiable {
    let id: Int
    let name: String
}

// MARK: - User Selections
struct UserEquipment: Codable {
    let id: Int?
    let profileId: String
    let equipmentId: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case equipmentId = "equipment_id"
    }
}

struct UserInjury: Codable, Identifiable {
    let id: Int?
    let profileId: String
    let injuryId: Int?
    let otherInjuryText: String?
    let isActive: Bool
    let reportedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case injuryId = "injury_id"
        case otherInjuryText = "other_injury_text"
        case isActive = "is_active"
        case reportedAt = "reported_at"
    }
}

struct UserSport: Codable {
    let id: Int?
    let profileId: String
    let sportId: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case sportId = "sport_id"
    }
}

struct UserGoal: Codable {
    let id: Int?
    let profileId: String
    let goalId: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case goalId = "goal_id"
    }
}

