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
    
    // Training Plan
    @Published var hasTrainingPlan = false
    @Published var trainingPlanInfo = ""
    @Published var trainingPlanImage: UIImage?
    @Published var trainingPlanImageRemoved = false // Track if image was removed
    
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
            
            // Load training plan data
            await loadTrainingPlanData()
            
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
        
        // Load training plan image if available
        if let imageURL = profile.trainingPlanImageURL {
            await loadTrainingPlanImage(from: imageURL)
        }
    }
    
    private func loadTrainingPlanImage(from imageURL: String) async {
        do {
            let signedURL = try await storageService.getSignedTrainingPlanImageURL(filePath: imageURL)
            if let url = URL(string: signedURL),
               let imageData = try? Data(contentsOf: url),
               let image = UIImage(data: imageData) {
                await MainActor.run {
                    self.trainingPlanImage = image
                }
            }
        } catch {
            print("Failed to load training plan image: \(error)")
        }
    }
    
    private func loadTrainingPlanData() async {
        // Load training plan image if it exists
        if let imageURL = try? await profileService.getProfile(userId: profileId).trainingPlanImageURL {
            await loadTrainingPlanImage(from: imageURL)
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
                imageURL = try await storageService.uploadTrainingPlanImage(
                    from: image.jpegData(compressionQuality: 0.8),
                    profileId: profileId
                )
            } else if trainingPlanImageRemoved {
                // If image was removed, set imageURL to nil
                imageURL = nil
            }
            
            // Create updated profile with weight conversion
            var updatedProfile = UserProfile(
                id: profileId,
                firstName: firstName,
                lastName: lastName,
                dateOfBirth: dateOfBirth,
                age: calculatedAge,
                sex: sex,
                heightCm: convertHeightToCm(),
                weightKg: nil, // Will be set using conversion method
                isPilot: false,
                onboardingCompleted: true,
                assessmentCompleted: true, // Preserve assessment status
                trainingPlanInfo: hasTrainingPlan ? trainingPlanInfo : nil,
                trainingPlanImageURL: imageURL,
                createdAt: Date(), // Will be preserved by database
                updatedAt: Date()
            )
            
            // Convert weight from lbs to kg
            if let weightLbs = Double(weight) {
                updatedProfile.setWeightLbs(weightLbs)
            }
            
            // Save to database
            try await profileService.updateProfile(updatedProfile)
            

            
            saveSuccess = true
            
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
        }
    }
    

    
    private func convertHeightToCm() -> Double? {
        guard let feet = Double(heightFeet), let inches = Double(heightInches) else { return nil }
        return (feet * 30.48) + (inches * 2.54)
    }
}
