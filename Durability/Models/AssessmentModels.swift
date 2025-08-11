import Foundation

// MARK: - Assessment
struct Assessment: Codable, Identifiable {
    let id: String
    let profileId: String
    let videoURL: String?
    let createdAt: Date
}

struct AssessmentResult: Codable, Identifiable {
    let id: String
    let assessmentId: String
    let bodyArea: String
    let durabilityScore: Double
    let rangeOfMotionScore: Double
    let flexibilityScore: Double
    let functionalStrengthScore: Double
    let mobilityScore: Double
    let aerobicCapacityScore: Double
}

