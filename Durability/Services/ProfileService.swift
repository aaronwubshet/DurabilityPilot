import Foundation
import Supabase

@MainActor
class ProfileService: ObservableObject {
    private let supabase = SupabaseManager.shared.client
    private let networkService = NetworkService()
    
    func getProfile(userId: String) async throws -> UserProfile {
        let result = await networkService.performWithRetry(
            operation: {
                let response: [UserProfile] = try await self.supabase
                    .from("profiles")
                    .select("*")
                    .eq("id", value: userId)
                    .execute()
                    .value
                
                guard let profile = response.first else {
                    throw ProfileError.notFound
                }
                
                return profile
            },
            operationName: "Get Profile"
        )
        
        switch result {
        case .success(let profile):
            return profile
        case .failure(let error, _, _):
            throw error
        case .noConnection:
            throw ProfileError.networkError
        }
    }
    
    func createProfile(_ profile: UserProfile) async throws {
        let result = await networkService.performWithRetry(
            operation: {
                // Create a struct for explicit field mapping
                struct ProfileInsertData: Codable {
                    let id: String
                    let firstName: String
                    let lastName: String
                    let isPilot: Bool
                    let onboardingCompleted: Bool
                    let assessmentCompleted: Bool
                    let createdAt: String
                    let updatedAt: String
                    let dateOfBirth: String?
                    let age: Int?
                    let sex: String?
                    let heightCm: Double?
                    let weightKg: Double?
                    let trainingPlanInfo: String?
                    let trainingPlanImageURL: String?
                    
                    enum CodingKeys: String, CodingKey {
                        case id
                        case firstName = "first_name"
                        case lastName = "last_name"
                        case isPilot = "is_pilot"
                        case onboardingCompleted = "onboarding_completed"
                        case assessmentCompleted = "assessment_completed"
                        case createdAt = "created_at"
                        case updatedAt = "updated_at"
                        case dateOfBirth = "date_of_birth"
                        case age
                        case sex
                        case heightCm = "height_cm"
                        case weightKg = "weight_kg"
                        case trainingPlanInfo = "training_plan_info"
                        case trainingPlanImageURL = "training_plan_image_url"
                    }
                }
                
                // Create a date-only formatter for dateOfBirth
                let dateOnlyFormatter = DateFormatter()
                dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
                dateOnlyFormatter.timeZone = TimeZone.current
                
                let insertData = ProfileInsertData(
                    id: profile.id,
                    firstName: profile.firstName,
                    lastName: profile.lastName,
                    isPilot: profile.isPilot,
                    onboardingCompleted: profile.onboardingCompleted,
                    assessmentCompleted: profile.assessmentCompleted,
                    createdAt: ISO8601DateFormatter().string(from: profile.createdAt),
                    updatedAt: ISO8601DateFormatter().string(from: profile.updatedAt),
                    dateOfBirth: profile.dateOfBirth.map { dateOnlyFormatter.string(from: $0) },
                    age: profile.age,
                    sex: profile.sex?.rawValue,
                    heightCm: profile.heightCm,
                    weightKg: profile.weightKg, // Already in kg from UserProfile
                    trainingPlanInfo: profile.trainingPlanInfo,
                    trainingPlanImageURL: profile.trainingPlanImageURL
                )
                
                _ = try await self.supabase
                    .from("profiles")
                    .insert(insertData)
                    .execute()
            },
            operationName: "Create Profile"
        )
        
        switch result {
        case .success:
            return
        case .failure(let error, _, _):
            throw ProfileError.databaseError(error)
        case .noConnection:
            throw ProfileError.networkError
        }
    }
    
    func updateProfile(_ profile: UserProfile) async throws {
        do {
            // Create a struct for explicit field mapping (same as createProfile)
            struct ProfileUpdateData: Codable {
                let firstName: String
                let lastName: String
                let isPilot: Bool
                let onboardingCompleted: Bool
                let assessmentCompleted: Bool
                let updatedAt: String
                let dateOfBirth: String?
                let age: Int?
                let sex: String?
                let heightCm: Double?
                let weightKg: Double?
                let trainingPlanInfo: String?
                let trainingPlanImageURL: String?
                
                enum CodingKeys: String, CodingKey {
                    case firstName = "first_name"
                    case lastName = "last_name"
                    case isPilot = "is_pilot"
                    case onboardingCompleted = "onboarding_completed"
                    case assessmentCompleted = "assessment_completed"
                    case updatedAt = "updated_at"
                    case dateOfBirth = "date_of_birth"
                    case age
                    case sex
                    case heightCm = "height_cm"
                    case weightKg = "weight_kg"
                    case trainingPlanInfo = "training_plan_info"
                    case trainingPlanImageURL = "training_plan_image_url"
                }
            }
            
            // Create a date-only formatter for dateOfBirth
            let dateOnlyFormatter = DateFormatter()
            dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
            dateOnlyFormatter.timeZone = TimeZone.current
            
            let updateData = ProfileUpdateData(
                firstName: profile.firstName,
                lastName: profile.lastName,
                isPilot: profile.isPilot,
                onboardingCompleted: profile.onboardingCompleted,
                assessmentCompleted: profile.assessmentCompleted,
                updatedAt: ISO8601DateFormatter().string(from: profile.updatedAt),
                dateOfBirth: profile.dateOfBirth.map { dateOnlyFormatter.string(from: $0) },
                age: profile.age,
                sex: profile.sex?.rawValue,
                heightCm: profile.heightCm,
                weightKg: profile.weightKg, // Already in kg from UserProfile
                trainingPlanInfo: profile.trainingPlanInfo,
                trainingPlanImageURL: profile.trainingPlanImageURL
            )
            
            _ = try await self.supabase
                .from("profiles")
                .update(updateData)
                .eq("id", value: profile.id)
                .execute()
            
        } catch {
            throw ProfileError.databaseError(error)
        }
    }
    
    // MARK: - Reference Data Methods
    
    func getEquipment() async throws -> [Equipment] {
        let response: [Equipment] = try await self.supabase
            .from("equipment")
            .select("*")
            .execute()
            .value
        
        return response
    }
    
    func getInjuries() async throws -> [Injury] {
        let response: [Injury] = try await self.supabase
            .from("injuries")
            .select("*")
            .execute()
            .value
        
        return response
    }
    
    func getSports() async throws -> [Sport] {
        let response: [Sport] = try await self.supabase
            .from("sports")
            .select("*")
            .execute()
            .value
        
        return response
    }
    
    func getGoals() async throws -> [Goal] {
        let response: [Goal] = try await self.supabase
            .from("goals")
            .select("*")
            .execute()
            .value
        
        return response
    }
    
    // MARK: - User Relationship Methods
    
    func saveUserEquipment(profileId: String, equipmentIds: [Int]) async throws {
        // Don't attempt to save if no equipment is selected
        guard !equipmentIds.isEmpty else {
            return
        }
        
        struct EquipmentData: Codable {
            let profileId: String
            let equipmentId: Int
            
            enum CodingKeys: String, CodingKey {
                case profileId = "profile_id"
                case equipmentId = "equipment_id"
            }
        }
        
        let userEquipment = equipmentIds.map { equipmentId in
            EquipmentData(profileId: profileId, equipmentId: equipmentId)
        }
        
        try await self.supabase
            .from("profile_equipment")
            .upsert(userEquipment)
            .execute()
    }
    
    func saveUserInjuries(profileId: String, injuries: [UserInjury]) async throws {
        // Don't attempt to save if no injuries are provided
        guard !injuries.isEmpty else {
            return
        }
        
        struct InjuryData: Codable {
            let profileId: String
            let injuryId: Int?
            let otherInjuryText: String?
            let isActive: Bool
            let reportedAt: String
            
            enum CodingKeys: String, CodingKey {
                case profileId = "profile_id"
                case injuryId = "injury_id"
                case otherInjuryText = "other_injury_text"
                case isActive = "is_active"
                case reportedAt = "reported_at"
            }
        }
        
        let injuryData = injuries.map { injury in
            InjuryData(
                profileId: profileId,
                injuryId: injury.injuryId,
                otherInjuryText: injury.otherInjuryText,
                isActive: injury.isActive,
                reportedAt: ISO8601DateFormatter().string(from: injury.reportedAt)
            )
        }
        
        try await self.supabase
            .from("profile_injuries")
            .upsert(injuryData)
            .execute()
    }
    
    func saveUserSports(profileId: String, sportIds: [Int]) async throws {
        // Don't attempt to save if no sports are selected
        guard !sportIds.isEmpty else {
            return
        }
        
        struct SportData: Codable {
            let profileId: String
            let sportId: Int
            
            enum CodingKeys: String, CodingKey {
                case profileId = "profile_id"
                case sportId = "sport_id"
            }
        }
        
        let userSports = sportIds.map { sportId in
            SportData(profileId: profileId, sportId: sportId)
        }
        
        try await self.supabase
            .from("profile_sports")
            .upsert(userSports)
            .execute()
    }
    
    func saveUserGoals(profileId: String, goalIds: [Int]) async throws {
        // Don't attempt to save if no goals are selected
        guard !goalIds.isEmpty else {
            return
        }
        
        struct GoalData: Codable {
            let profileId: String
            let goalId: Int
            
            enum CodingKeys: String, CodingKey {
                case profileId = "profile_id"
                case goalId = "goal_id"
            }
        }
        
        let userGoals = goalIds.map { goalId in
            GoalData(profileId: profileId, goalId: goalId)
        }
        
        try await self.supabase
            .from("profile_goals")
            .upsert(userGoals)
            .execute()
    }
    
    // MARK: - User Selections Loading
    
    /// Gets user's equipment selections
    func getUserEquipment(profileId: String) async throws -> [Int] {
        let response: [UserEquipment] = try await self.supabase
            .from("profile_equipment")
            .select("equipment_id")
            .eq("profile_id", value: profileId)
            .execute()
            .value
        
        let equipmentIds = response.map { $0.equipmentId }
        return equipmentIds
    }
    
    /// Gets user's injury selections
    func getUserInjuries(profileId: String) async throws -> [UserInjury] {
        let response: [UserInjury] = try await self.supabase
            .from("profile_injuries")
            .select("*")
            .eq("profile_id", value: profileId)
            .execute()
            .value
        
        return response
    }
    
    /// Gets user's sports selections
    func getUserSports(profileId: String) async throws -> [Int] {
        let response: [UserSport] = try await self.supabase
            .from("profile_sports")
            .select("sport_id")
            .eq("profile_id", value: profileId)
            .execute()
            .value
        
        let sportIds = response.map { $0.sportId }
        return sportIds
    }
    
    /// Gets user's goals selections
    func getUserGoals(profileId: String) async throws -> [Int] {
        let response: [UserGoal] = try await self.supabase
            .from("profile_goals")
            .select("goal_id")
            .eq("profile_id", value: profileId)
            .execute()
            .value
        
        let goalIds = response.map { $0.goalId }
        return goalIds
    }
    
    // MARK: - Connection Testing
    
    /// Simple connection test that relies on RLS policies
    func testConnection() async throws {
        // Simple query that will work if authenticated and RLS allows
        let _: [String] = try await self.supabase
            .from("profiles")
            .select("id")
            .limit(1)
            .execute()
            .value
    }
}

enum ProfileError: Error, LocalizedError {
    case notFound
    case invalidData
    case networkError
    case databaseError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Profile not found"
        case .invalidData:
            return "Invalid profile data"
        case .networkError:
            return "Network connection error"
        case .databaseError(let error):
            return "Database error: \(error.localizedDescription)"
        }
    }
}
