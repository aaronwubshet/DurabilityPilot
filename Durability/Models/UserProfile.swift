import Foundation

// MARK: - User Profile
struct UserProfile: Codable, Identifiable {
    let id: String
    var firstName: String
    var lastName: String
    var email: String
    var age: Int?
    var sex: Sex?
    var heightCm: Double?
    var weightKg: Double?
    var isPilot: Bool = false
    var onboardingCompleted: Bool = false
    var assessmentCompleted: Bool = false
    var trainingPlanInfo: String?
    var trainingPlanImageURL: String?
    var createdAt: Date
    var updatedAt: Date
    
    enum Sex: String, CaseIterable, Codable {
        case male = "male"
        case female = "female"
        case other = "other"
        case preferNotToSay = "prefer_not_to_say"
    }
}

extension UserProfile.Sex {
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}
