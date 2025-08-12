import Foundation
import Supabase

@MainActor
class ProfileService: ObservableObject {
    private let supabase = SupabaseManager.shared.client
    
    func getProfile(userId: String) async throws -> UserProfile {
        let response: [UserProfile] = try await supabase
            .from("profiles")
            .select("*")
            .eq("id", value: userId)
            .execute()
            .value
        
        guard let profile = response.first else {
            throw ProfileError.notFound
        }
        
        return profile
    }
    
    func createProfile(_ profile: UserProfile) async throws {
        print("ProfileService: Creating profile for user: \(profile.id)")
        
        do {
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
            
            let insertData = ProfileInsertData(
                id: profile.id,
                firstName: profile.firstName,
                lastName: profile.lastName,
                isPilot: profile.isPilot,
                onboardingCompleted: profile.onboardingCompleted,
                assessmentCompleted: profile.assessmentCompleted,
                createdAt: ISO8601DateFormatter().string(from: profile.createdAt),
                updatedAt: ISO8601DateFormatter().string(from: profile.updatedAt),
                dateOfBirth: profile.dateOfBirth.map { ISO8601DateFormatter().string(from: $0) },
                age: profile.age,
                sex: profile.sex?.rawValue,
                heightCm: profile.heightCm,
                weightKg: profile.weightKg,
                trainingPlanInfo: profile.trainingPlanInfo,
                trainingPlanImageURL: profile.trainingPlanImageURL
            )
            
            _ = try await supabase
                .from("profiles")
                .insert(insertData)
                .execute()
            
            print("ProfileService: Profile created successfully")
            
        } catch {
            print("ProfileService: Failed to create profile: \(error.localizedDescription)")
            throw ProfileError.databaseError(error)
        }
    }
    
    func updateProfile(_ profile: UserProfile) async throws {
        print("ProfileService: Updating profile for user: \(profile.id)")
        
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
            
            let updateData = ProfileUpdateData(
                firstName: profile.firstName,
                lastName: profile.lastName,
                isPilot: profile.isPilot,
                onboardingCompleted: profile.onboardingCompleted,
                assessmentCompleted: profile.assessmentCompleted,
                updatedAt: ISO8601DateFormatter().string(from: profile.updatedAt),
                dateOfBirth: profile.dateOfBirth.map { ISO8601DateFormatter().string(from: $0) },
                age: profile.age,
                sex: profile.sex?.rawValue,
                heightCm: profile.heightCm,
                weightKg: profile.weightKg,
                trainingPlanInfo: profile.trainingPlanInfo,
                trainingPlanImageURL: profile.trainingPlanImageURL
            )
            
            _ = try await supabase
                .from("profiles")
                .update(updateData)
                .eq("id", value: profile.id)
                .execute()
            
            print("ProfileService: Profile updated successfully")
            
        } catch {
            print("ProfileService: Failed to update profile: \(error.localizedDescription)")
            throw ProfileError.databaseError(error)
        }
    }
    
    // MARK: - Reference Data Methods
    
    func getEquipment() async throws -> [Equipment] {
        let response: [Equipment] = try await supabase
            .from("equipment")
            .select("*")
            .execute()
            .value
        return response
    }
    
    func getInjuries() async throws -> [Injury] {
        let response: [Injury] = try await supabase
            .from("injuries")
            .select("*")
            .execute()
            .value
        return response
    }
    
    func getSports() async throws -> [Sport] {
        let response: [Sport] = try await supabase
            .from("sports")
            .select("*")
            .execute()
            .value
        return response
    }
    
    func getGoals() async throws -> [Goal] {
        let response: [Goal] = try await supabase
            .from("goals")
            .select("*")
            .execute()
            .value
        return response
    }
    
    // MARK: - User Relationship Methods
    
    func saveUserEquipment(profileId: String, equipmentIds: [Int]) async throws {
        let userEquipment = equipmentIds.map { equipmentId in
            UserEquipment(id: nil, profileId: profileId, equipmentId: equipmentId)
        }
        
        try await supabase
            .from("profile_equipment")
            .upsert(userEquipment)
            .execute()
    }
    
    func saveUserInjuries(profileId: String, injuries: [UserInjury]) async throws {
        try await supabase
            .from("profile_injuries")
            .upsert(injuries)
            .execute()
    }
    
    func saveUserSports(profileId: String, sportIds: [Int]) async throws {
        let userSports = sportIds.map { sportId in
            UserSport(id: nil, profileId: profileId, sportId: sportId)
        }
        
        try await supabase
            .from("profile_sports")
            .upsert(userSports)
            .execute()
    }
    
    func saveUserGoals(profileId: String, goalIds: [Int]) async throws {
        let userGoals = goalIds.map { goalId in
            UserGoal(id: nil, profileId: profileId, goalId: goalId)
        }
        
        try await supabase
            .from("profile_goals")
            .upsert(userGoals)
            .execute()
    }
    
    // MARK: - User Selections Loading
    
    /// Gets user's equipment selections
    func getUserEquipment(profileId: String) async throws -> [Int] {
        let response: [UserEquipment] = try await supabase
            .from("profile_equipment")
            .select("equipment_id")
            .eq("profile_id", value: profileId)
            .execute()
            .value
        
        return response.map { $0.equipmentId }
    }
    
    /// Gets user's injury selections
    func getUserInjuries(profileId: String) async throws -> [UserInjury] {
        let response: [UserInjury] = try await supabase
            .from("profile_injuries")
            .select("*")
            .eq("profile_id", value: profileId)
            .execute()
            .value
        
        return response
    }
    
    /// Gets user's sports selections
    func getUserSports(profileId: String) async throws -> [Int] {
        let response: [UserSport] = try await supabase
            .from("profile_sports")
            .select("sport_id")
            .eq("profile_id", value: profileId)
            .execute()
            .value
        
        return response.map { $0.sportId }
    }
    
    /// Gets user's goals selections
    func getUserGoals(profileId: String) async throws -> [Int] {
        let response: [UserGoal] = try await supabase
            .from("profile_goals")
            .select("goal_id")
            .eq("profile_id", value: profileId)
            .execute()
            .value
        
        return response.map { $0.goalId }
    }
    
    // MARK: - Connection Testing
    
    /// Simple connection test that relies on RLS policies
    func testConnection() async throws {
        // Simple query that will work if authenticated and RLS allows
        let _: [String] = try await supabase
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
