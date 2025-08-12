import Foundation

// MARK: - User Profile
struct UserProfile: Codable, Identifiable {
    let id: String
    var firstName: String
    var lastName: String
    var dateOfBirth: Date?
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
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case dateOfBirth = "date_of_birth"
        case age
        case sex
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case isPilot = "is_pilot"
        case onboardingCompleted = "onboarding_completed"
        case assessmentCompleted = "assessment_completed"
        case trainingPlanInfo = "training_plan_info"
        case trainingPlanImageURL = "training_plan_image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
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
