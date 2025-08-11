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
}

struct UserInjury: Codable, Identifiable {
    let id: String
    let profileId: String
    let injuryId: Int?
    let otherInjuryText: String?
    let isActive: Bool
    let reportedAt: Date
}

struct UserSport: Codable {
    let profileId: String
    let sportId: Int
}

struct UserGoal: Codable {
    let profileId: String
    let goalId: Int
}

