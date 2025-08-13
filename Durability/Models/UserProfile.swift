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
    
    // Custom date decoding for dateOfBirth
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        age = try container.decodeIfPresent(Int.self, forKey: .age)
        sex = try container.decodeIfPresent(Sex.self, forKey: .sex)
        heightCm = try container.decodeIfPresent(Double.self, forKey: .heightCm)
        
        // Weight is stored in kg in database, keep it as kg for internal use
        weightKg = try container.decodeIfPresent(Double.self, forKey: .weightKg)
        
        isPilot = try container.decodeIfPresent(Bool.self, forKey: .isPilot) ?? false
        onboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .onboardingCompleted) ?? false
        assessmentCompleted = try container.decodeIfPresent(Bool.self, forKey: .assessmentCompleted) ?? false
        trainingPlanInfo = try container.decodeIfPresent(String.self, forKey: .trainingPlanInfo)
        trainingPlanImageURL = try container.decodeIfPresent(String.self, forKey: .trainingPlanImageURL)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        // Custom date decoding for dateOfBirth
        if let dateString = try container.decodeIfPresent(String.self, forKey: .dateOfBirth) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            dateOfBirth = dateFormatter.date(from: dateString)
        } else {
            dateOfBirth = nil
        }
    }
    
    // Custom encoding to ensure dateOfBirth is encoded as yyyy-MM-dd
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encodeIfPresent(age, forKey: .age)
        try container.encodeIfPresent(sex, forKey: .sex)
        try container.encodeIfPresent(heightCm, forKey: .heightCm)
        try container.encodeIfPresent(weightKg, forKey: .weightKg)
        try container.encode(isPilot, forKey: .isPilot)
        try container.encode(onboardingCompleted, forKey: .onboardingCompleted)
        try container.encode(assessmentCompleted, forKey: .assessmentCompleted)
        try container.encodeIfPresent(trainingPlanInfo, forKey: .trainingPlanInfo)
        try container.encodeIfPresent(trainingPlanImageURL, forKey: .trainingPlanImageURL)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        
        // Custom date encoding for dateOfBirth
        if let dateOfBirth = dateOfBirth {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone.current
            try container.encode(dateFormatter.string(from: dateOfBirth), forKey: .dateOfBirth)
        }
    }
    
    // Custom initializer for creating UserProfile instances
    init(id: String, firstName: String, lastName: String, dateOfBirth: Date?, age: Int?, sex: Sex?, heightCm: Double?, weightKg: Double?, isPilot: Bool = false, onboardingCompleted: Bool = false, assessmentCompleted: Bool = false, trainingPlanInfo: String?, trainingPlanImageURL: String?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.age = age
        self.sex = sex
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.isPilot = isPilot
        self.onboardingCompleted = onboardingCompleted
        self.assessmentCompleted = assessmentCompleted
        self.trainingPlanInfo = trainingPlanInfo
        self.trainingPlanImageURL = trainingPlanImageURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Weight Conversion Properties
    
    /// Weight in pounds (converted from kg for display)
    var weightLbs: Double? {
        guard let weightKg = weightKg else { return nil }
        return weightKg * 2.20462
    }
    
    /// Set weight in pounds (converts to kg for storage)
    mutating func setWeightLbs(_ pounds: Double?) {
        if let pounds = pounds {
            weightKg = pounds * 0.453592
        } else {
            weightKg = nil
        }
    }
    
    /// Set weight in kilograms (direct assignment)
    mutating func setWeightKg(_ kilograms: Double?) {
        weightKg = kilograms
    }
    
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
