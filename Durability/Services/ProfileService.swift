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
        try await supabase
            .from("profiles")
            .insert(profile)
            .execute()
    }
    
    func updateProfile(_ profile: UserProfile) async throws {
        try await supabase
            .from("profiles")
            .update(profile)
            .eq("id", value: profile.id)
            .execute()
    }
    
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
    
    func saveUserEquipment(profileId: String, equipmentIds: [Int]) async throws {
        let userEquipment = equipmentIds.map { equipmentId in
            UserEquipment(profileId: profileId, equipmentId: equipmentId)
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
            UserSport(profileId: profileId, sportId: sportId)
        }
        
        try await supabase
            .from("profile_sports")
            .upsert(userSports)
            .execute()
    }
    
    func saveUserGoals(profileId: String, goalIds: [Int]) async throws {
        let userGoals = goalIds.map { goalId in
            UserGoal(profileId: profileId, goalId: goalId)
        }
        
        try await supabase
            .from("profile_goals")
            .upsert(userGoals)
            .execute()
    }
}

enum ProfileError: Error {
    case notFound
    case invalidData
    case networkError
}
