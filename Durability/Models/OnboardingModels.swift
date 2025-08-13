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
    let profileId: String
    let equipmentId: Int
    
    enum CodingKeys: String, CodingKey {
        case profileId = "profile_id"
        case equipmentId = "equipment_id"
    }
    
    // Custom encoding to ensure profileId is sent as string
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(equipmentId, forKey: .equipmentId)
        try container.encode(profileId, forKey: .profileId)
    }
}

struct UserInjury: Codable, Identifiable {
    let profileId: String
    let injuryId: Int?
    let otherInjuryText: String?
    let isActive: Bool
    let reportedAt: Date
    
    // Use profileId as the identifier since there's no separate id column
    var id: String { profileId }
    
    enum CodingKeys: String, CodingKey {
        case profileId = "profile_id"
        case injuryId = "injury_id"
        case otherInjuryText = "other_injury_text"
        case isActive = "is_active"
        case reportedAt = "reported_at"
    }
    
    // Custom encoding to ensure profileId is sent as string
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(injuryId, forKey: .injuryId)
        try container.encodeIfPresent(otherInjuryText, forKey: .otherInjuryText)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(reportedAt, forKey: .reportedAt)
        try container.encode(profileId, forKey: .profileId)
    }
}

struct UserSport: Codable {
    let profileId: String
    let sportId: Int
    
    enum CodingKeys: String, CodingKey {
        case profileId = "profile_id"
        case sportId = "sport_id"
    }
    
    // Custom encoding to ensure profileId is sent as string
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(sportId, forKey: .sportId)
        try container.encode(profileId, forKey: .profileId)
    }
}

struct UserGoal: Codable {
    let profileId: String
    let goalId: Int
    
    enum CodingKeys: String, CodingKey {
        case profileId = "profile_id"
        case goalId = "goal_id"
    }
    
    // Custom encoding to ensure profileId is sent as string
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(goalId, forKey: .goalId)
        try container.encode(profileId, forKey: .profileId)
    }
}

