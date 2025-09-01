import Foundation

// MARK: - Assessment
struct Assessment: Codable, Identifiable {
    let assessmentId: Int? // Optional for creation, populated after database insert
    let profileId: String
    var videoURL: String?
    let createdAt: Date
    
    // Computed property for Identifiable conformance
    var id: String {
        return assessmentId?.description ?? UUID().uuidString
    }
    
    enum CodingKeys: String, CodingKey {
        case assessmentId = "assessment_id"
        case profileId = "profile_id"
        case videoURL = "video_url"
        case createdAt = "created_at"
    }
}

struct AssessmentResult: Codable, Identifiable {
    let id: Int? // Auto-incrementing primary key from database (optional for creation)
    var assessmentId: Int? // This should be the integer from the assessments table (optional for creation)
    let profileId: String // This should be the UUID from the profiles table
    let bodyArea: String
    let durabilityScore: Double
    let rangeOfMotionScore: Double
    let flexibilityScore: Double
    let functionalStrengthScore: Double
    let mobilityScore: Double
    let aerobicCapacityScore: Double
    
    // Computed property for Identifiable conformance
    var identifier: String {
        return "\(assessmentId ?? 0)_\(bodyArea)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case assessmentId = "assessment_id"
        case profileId = "profile_id"
        case bodyArea = "body_area"
        case durabilityScore = "durability_score"
        case rangeOfMotionScore = "range_of_motion_score"
        case flexibilityScore = "flexibility_score"
        case functionalStrengthScore = "functional_strength_score"
        case mobilityScore = "mobility_score"
        case aerobicCapacityScore = "aerobic_capacity_score"
    }
}

