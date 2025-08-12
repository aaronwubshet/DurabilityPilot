import SwiftUI
import Foundation

@MainActor
class ProfileEditViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var saveSuccess = false
    
    // Basic Info
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var dateOfBirth = Date()
    @Published var sex: UserProfile.Sex? = nil
    @Published var heightFeet = ""
    @Published var heightInches = ""
    @Published var weight = ""
    
    // Equipment
    @Published var selectedEquipment: Set<Int> = []
    @Published var availableEquipment: [Equipment] = []
    
    // Injuries
    @Published var hasInjuries = false
    @Published var selectedInjuries: Set<Int> = []
    @Published var otherInjuryText = ""
    @Published var availableInjuries: [Injury] = []
    
    // Training Plan
    @Published var hasTrainingPlan = false
    @Published var trainingPlanInfo = ""
    @Published var trainingPlanImage: UIImage?
    
    // Sports
    @Published var selectedSports: Set<Int> = []
    @Published var availableSports: [Sport] = []
    
    // Goals
    @Published var selectedGoals: Set<Int> = []
    @Published var availableGoals: [Goal] = []
    
    private let profileService = ProfileService()
    private let storageService = StorageService()
    private let profileId: String
    
    init(profileId: String) {
        self.profileId = profileId
    }
    
    var calculatedAge: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year ?? 0
    }
    
    var canSave: Bool {
        !firstName.isEmpty && !lastName.isEmpty && calculatedAge > 0
    }
    
    // MARK: - Data Loading
    
    func loadProfileData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load basic profile
            let profile = try await profileService.getProfile(userId: profileId)
            await loadBasicInfo(from: profile)
            
            // Load related data
            await loadEquipmentData()
            await loadInjuryData()
            await loadSportsData()
            await loadGoalsData()
            
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
        }
    }
    
    private func loadBasicInfo(from profile: UserProfile) async {
        firstName = profile.firstName
        lastName = profile.lastName
        dateOfBirth = profile.dateOfBirth ?? Date()
        sex = profile.sex
        
        // Convert height from cm to feet/inches
        if let heightCm = profile.heightCm {
            let totalInches = heightCm / 2.54
            let feet = Int(totalInches / 12)
            let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            heightFeet = String(feet)
            heightInches = String(inches)
        }
        
        // Convert weight from kg to lbs
        if let weightKg = profile.weightKg {
            let weightLbs = weightKg * 2.20462
            weight = String(Int(weightLbs))
        }
        
        // Training plan info
        hasTrainingPlan = profile.trainingPlanInfo != nil
        trainingPlanInfo = profile.trainingPlanInfo ?? ""
    }
    
    private func loadEquipmentData() async {
        do {
            availableEquipment = try await profileService.getEquipment()
            // TODO: Load user's selected equipment from profile_equipment table
        } catch {
            print("Failed to load equipment: \(error)")
        }
    }
    
    private func loadInjuryData() async {
        do {
            availableInjuries = try await profileService.getInjuries()
            // TODO: Load user's selected injuries from profile_injuries table
        } catch {
            print("Failed to load injuries: \(error)")
        }
    }
    
    private func loadSportsData() async {
        do {
            availableSports = try await profileService.getSports()
            // TODO: Load user's selected sports from profile_sports table
        } catch {
            print("Failed to load sports: \(error)")
        }
    }
    
    private func loadGoalsData() async {
        do {
            availableGoals = try await profileService.getGoals()
            // TODO: Load user's selected goals from profile_goals table
        } catch {
            print("Failed to load goals: \(error)")
        }
    }
    
    // MARK: - Data Saving
    
    func saveProfile() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Handle training plan image upload if changed
            var imageURL: String?
            if let image = trainingPlanImage {
                imageURL = try await storageService.uploadImage(
                    from: image.jpegData(compressionQuality: 0.8),
                    bucket: "training-plan-images"
                )
            }
            
            // Create updated profile
            let updatedProfile = UserProfile(
                id: profileId,
                firstName: firstName,
                lastName: lastName,
                dateOfBirth: dateOfBirth,
                age: calculatedAge,
                sex: sex,
                heightCm: convertHeightToCm(),
                weightKg: Double(weight),
                isPilot: false,
                onboardingCompleted: true,
                assessmentCompleted: true, // Preserve assessment status
                trainingPlanInfo: hasTrainingPlan ? trainingPlanInfo : nil,
                trainingPlanImageURL: imageURL,
                createdAt: Date(), // Will be preserved by database
                updatedAt: Date()
            )
            
            // Save to database
            try await profileService.updateProfile(updatedProfile)
            
            // Save related data
            await saveRelatedData()
            
            saveSuccess = true
            
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
        }
    }
    
    private func saveRelatedData() async {
        // Save equipment selections
        if !selectedEquipment.isEmpty {
            try? await profileService.saveUserEquipment(
                profileId: profileId,
                equipmentIds: Array(selectedEquipment)
            )
        }
        
        // Save injury selections
        if !selectedInjuries.isEmpty {
            let userInjuries = selectedInjuries.map { injuryId in
                UserInjury(
                    id: nil, // Database will auto-generate ID
                    profileId: profileId,
                    injuryId: injuryId,
                    otherInjuryText: otherInjuryText.isEmpty ? nil : otherInjuryText,
                    isActive: true,
                    reportedAt: Date()
                )
            }
            try? await profileService.saveUserInjuries(
                profileId: profileId,
                injuries: userInjuries
            )
        }
        
        // Save sports selections
        if !selectedSports.isEmpty {
            try? await profileService.saveUserSports(
                profileId: profileId,
                sportIds: Array(selectedSports)
            )
        }
        
        // Save goals selections
        if !selectedGoals.isEmpty {
            try? await profileService.saveUserGoals(
                profileId: profileId,
                goalIds: Array(selectedGoals)
            )
        }
    }
    
    private func convertHeightToCm() -> Double? {
        guard let feet = Double(heightFeet), let inches = Double(heightInches) else { return nil }
        return (feet * 30.48) + (inches * 2.54)
    }
}
