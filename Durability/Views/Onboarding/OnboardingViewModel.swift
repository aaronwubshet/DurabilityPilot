import SwiftUI
import UIKit

enum OnboardingStep: Int, CaseIterable {
    case healthKit = 0
    case basicInfo = 1
    case equipment = 2
    case injuries = 3
    case trainingPlan = 4
    case sports = 5
    case goals = 6
}

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .healthKit
    @Published var isLoading = false
    @Published var isTransitioningToSports = false
    @Published var errorMessage: String?
    
    // Access to app state
    private var appState: AppState?
    
    func setAppState(_ appState: AppState) {
        self.appState = appState
        // Populate name fields with Apple Sign-In data if available
        populateNameFromAppleSignIn()
        // Load existing profile data from database if available
        Task {
            await loadExistingProfileData()
        }
    }
    
    /// Loads existing profile data from database if available
    private func loadExistingProfileData() async {
        guard let appState = appState,
              let userId = appState.authService.user?.id.uuidString else {
            return
        }
        
        do {
            let existingProfile = try await appState.profileService.getProfile(userId: userId)
            
            // Populate fields with existing data
            await MainActor.run {
                firstName = existingProfile.firstName
                lastName = existingProfile.lastName
                
                if let dateOfBirth = existingProfile.dateOfBirth {
                    self.dateOfBirth = dateOfBirth
                }
                
                if let sex = existingProfile.sex {
                    self.sex = sex
                }
                
                if let heightCm = existingProfile.heightCm {
                    let feet = Int(heightCm / 30.48)
                    let inches = Int((heightCm.truncatingRemainder(dividingBy: 30.48)) / 2.54)
                    heightFeet = String(feet)
                    heightInches = String(inches)
                }
                
                if let weightKg = existingProfile.weightKg {
                    let weightLbs = Int(weightKg * 2.20462)
                    weight = String(weightLbs)
                }
            }
            
        } catch {
            // This is normal for first-time users
        }
    }
    
    // Basic Info
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var dateOfBirth: Date? = nil
    @Published var sex: UserProfile.Sex? = nil
    @Published var heightFeet = ""
    @Published var heightInches = ""
    @Published var weight = ""
    
    // Equipment
    @Published var selectedEquipment: Set<Int> = []
    
    // Injuries
    @Published var hasInjuries = false
    @Published var selectedInjuries: Set<Int> = []
    @Published var otherInjuryText = ""
    
    // Training Plan
    @Published var hasTrainingPlan = false
    @Published var trainingPlanInfo = ""
    @Published var trainingPlanImage: UIImage?
    
    // Sports
    @Published var selectedSports: Set<Int> = []
    
    // Goals
    @Published var selectedGoals: Set<Int> = []
    
    // HealthKit
    @Published var healthKitAuthorized = false
    
    var currentStepProgress: Double {
        Double(currentStep.rawValue) / Double(OnboardingStep.allCases.count - 1)
    }
    
    var calculatedAge: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth ?? Date(), to: Date())
        return ageComponents.year ?? 0
    }
    
    var canProceed: Bool {
        switch currentStep {
        case .basicInfo:
            // Always require user to review and confirm basic info, even if pre-populated
            let basicInfoValid = !firstName.isEmpty && !lastName.isEmpty && calculatedAge > 0
            return basicInfoValid
        case .equipment:
            return true // Allow proceeding even if no equipment selected
        case .injuries:
            return true // Always can proceed
        case .trainingPlan:
            return true // Always can proceed
        case .sports:
            // Make sports selection optional for now
            let sportsValid = true // !selectedSports.isEmpty
            return sportsValid
        case .goals:
            // Make goals selection optional for now
            let goalsValid = true // !selectedGoals.isEmpty
            return goalsValid
        case .healthKit:
            return true // Always can proceed
        }
    }
    
    func nextStep() async {
        // Dismiss keyboard when moving between steps
        dismissKeyboard()
        
        // Set transition loading state when moving from training plan to sports
        if currentStep == .trainingPlan {
            isTransitioningToSports = true
        }
        
        // Save current step's data before proceeding
        await saveCurrentStepData()
        
        if currentStep.rawValue < OnboardingStep.allCases.count - 1 {
            currentStep = OnboardingStep(rawValue: currentStep.rawValue + 1)!
            
            // Populate name fields when reaching basic info step
            if currentStep == .basicInfo {
                populateNameFromAppleSignIn()
            }
            
            // Clear transition loading state after moving to sports
            if currentStep == .sports {
                isTransitioningToSports = false
            }
        }
    }
    
    func previousStep() {
        // Dismiss keyboard when moving between steps
        dismissKeyboard()
        
        if currentStep.rawValue > 0 {
            currentStep = OnboardingStep(rawValue: currentStep.rawValue - 1)!
        }
    }
    
    func completeOnboarding() async {
        // Add protection against accidental completion
        guard currentStep == OnboardingStep.allCases.last else {
            return
        }
        
        guard let appState = appState else {
            errorMessage = "App state not available"
            return
        }
        
        // Save current step data before completing onboarding
        await saveCurrentStepData()
        
        // Validate required fields first
        guard let userId = appState.authService.user?.id.uuidString, !userId.isEmpty else {
            errorMessage = "User ID is missing"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        var imageURL: String?
        if let image = trainingPlanImage {
            do {
                imageURL = try await appState.storageService.uploadTrainingPlanImage(
                    from: image.jpegData(compressionQuality: 0.8),
                    profileId: userId
                )
            } catch {
                errorMessage = "Failed to upload image: \(error.localizedDescription)"
            }
        }
        
        guard !firstName.isEmpty, !lastName.isEmpty else {
            errorMessage = "First name and last name are required"
            return
        }
        
        let heightCm = convertHeightToCm()
        let weightLbs = Double(weight)
        
        // Create profile with weight in kg (converted from lbs)
        var profile = UserProfile(
            id: userId,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth,
            age: calculatedAge,
            sex: sex,
            heightCm: heightCm,
            weightKg: nil, // Will be set using the conversion method
            isPilot: true,
            onboardingCompleted: true,
            assessmentCompleted: false,
            trainingPlanInfo: hasTrainingPlan ? trainingPlanInfo : nil,
            trainingPlanImageURL: imageURL,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Convert weight from lbs to kg
        if let weightLbs = weightLbs {
            profile.setWeightLbs(weightLbs)
        }
        
        do {
            // Try to update existing profile first, if it fails, create new one
            do {
                try await appState.profileService.updateProfile(profile)
            } catch {
                // If update fails (profile doesn't exist), create new one
                try await appState.profileService.createProfile(profile)
            }
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
            // Don't advance app state if profile creation failed
            return
        }
        
        // Only advance app state if profile was successfully created
        await MainActor.run {
            // Update the current user profile with onboarding completed
            var updatedProfile = appState.currentUser
            updatedProfile?.onboardingCompleted = true
            updatedProfile?.updatedAt = Date()
            
            if let profile = updatedProfile {
                appState.currentUser = profile
                // Set app flow state to assessment since onboarding is now complete
                appState.appFlowState = .assessment
            }
            

            
            // Note: User selections are now saved immediately when made, so no need to save again here
        }
    }
    
    private func convertHeightToCm() -> Double? {
        guard let feet = Double(heightFeet), let inches = Double(heightInches) else { return nil }
        return (feet * 30.48) + (inches * 2.54)
    }
    
    /// Populates first and last name fields with Apple Sign-In data if available
    private func populateNameFromAppleSignIn() {
        guard let appState = appState,
              let appleData = appState.authService.getAppleSignInData() else {
            return
        }
        
        // Only populate if the fields are currently empty
        if firstName.isEmpty, let appleFirstName = appleData.firstName {
            firstName = appleFirstName
        }
        
        if lastName.isEmpty, let appleLastName = appleData.lastName {
            lastName = appleLastName
        }
        
        // Clear the Apple Sign-In data after using it to prevent re-population
        if !firstName.isEmpty || !lastName.isEmpty {
            appState.authService.clearAppleSignInData()
        }
    }
    
    /// Public method to populate name fields from Apple Sign-In data when needed
    func populateNameFromAppleSignInIfNeeded() {
        populateNameFromAppleSignIn()
    }
    
    // MARK: - Immediate Database Saving
    
    /// Saves equipment selection to database immediately
    func saveEquipmentSelection() async {
        guard let appState = appState,
              let userId = appState.authService.user?.id.uuidString else { 
            return 
        }
        
        do {
            try await appState.profileService.saveUserEquipment(profileId: userId, equipmentIds: Array(selectedEquipment))
        } catch {
            // Handle error silently
        }
    }
    
    /// Saves goals selection to database immediately
    func saveGoalsSelection() async {
        guard let appState = appState,
              let userId = appState.authService.user?.id.uuidString else { return }
        
        do {
            try await appState.profileService.saveUserGoals(profileId: userId, goalIds: Array(selectedGoals))
        } catch {
            // Handle error silently
        }
    }
    
    /// Saves sports selection to database immediately
    func saveSportsSelection() async {
        guard let appState = appState,
              let userId = appState.authService.user?.id.uuidString else { return }
        
        do {
            try await appState.profileService.saveUserSports(profileId: userId, sportIds: Array(selectedSports))
        } catch {
            // Handle error silently
        }
    }
    
    /// Saves injuries selection to database immediately
    func saveInjuriesSelection() async {
        guard let appState = appState,
              let userId = appState.authService.user?.id.uuidString else { return }
        
        do {
            var injuries: [UserInjury] = []
            
            // Add selected injuries
            for injuryId in selectedInjuries {
                // Check if this is the "Other" injury (ID 9 based on the database)
                let isOtherInjury = injuryId == 9 // "Other" injury ID
                
                injuries.append(UserInjury(
                    profileId: userId,
                    injuryId: injuryId,
                    otherInjuryText: isOtherInjury ? otherInjuryText.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
                    isActive: true,
                    reportedAt: Date()
                ))
            }
            
            try await appState.profileService.saveUserInjuries(profileId: userId, injuries: injuries)
        } catch {
            // Handle error silently
        }
    }
    
    /// Saves training plan info to database immediately
    func saveTrainingPlanInfo() async {
        guard let appState = appState,
              let userId = appState.authService.user?.id.uuidString else { return }
        
        do {
            var profile = try await appState.profileService.getProfile(userId: userId)
            profile.trainingPlanInfo = trainingPlanInfo
            profile.updatedAt = Date()
            try await appState.profileService.updateProfile(profile)
        } catch {
            // Handle error silently
        }
    }
    
    /// Saves training plan image to storage and database immediately
    func saveTrainingPlanImage() async {
        guard let appState = appState,
              let userId = appState.authService.user?.id.uuidString,
              let image = trainingPlanImage else { return }
        
        do {
            // Upload image to storage
            let imageURL = try await appState.storageService.uploadTrainingPlanImage(
                from: image.jpegData(compressionQuality: 0.8),
                profileId: userId
            )
            
            // Update profile with image URL
            var profile = try await appState.profileService.getProfile(userId: userId)
            profile.trainingPlanImageURL = imageURL
            profile.updatedAt = Date()
            try await appState.profileService.updateProfile(profile)
        } catch {
            // Handle error silently
        }
    }
    
    /// Saves basic profile info (name, date of birth, height, weight, sex) to database immediately
    func saveBasicProfileInfo() async {
        guard let appState = appState,
              let userId = appState.authService.user?.id.uuidString else { return }
        
        do {
            var profile = try await appState.profileService.getProfile(userId: userId)
            

            
            // Update basic profile fields
            profile.firstName = firstName
            profile.lastName = lastName
            profile.dateOfBirth = dateOfBirth
            profile.age = calculatedAge
            profile.sex = sex
            
            // Convert height and weight
            if let heightCm = convertHeightToCm() {
                profile.heightCm = heightCm
            }
            if let weightLbs = Double(weight) {
                profile.setWeightLbs(weightLbs) // Convert lbs to kg using the new method
            }
            
            profile.updatedAt = Date()
            
            try await appState.profileService.updateProfile(profile)
        } catch {
            // Handle error silently
        }
    }
    
    /// Saves the current step's data to the database before proceeding to the next step
    private func saveCurrentStepData() async {
        guard appState != nil else { return }
        
        switch currentStep {
        case .basicInfo:
            // Save basic profile info (name, date of birth, height, weight, sex)
            await saveBasicProfileInfo()
            
        case .equipment:
            // Save equipment selections
            await saveEquipmentSelection()
            
        case .injuries:
            // Save injury selections
            await saveInjuriesSelection()
            
        case .trainingPlan:
            // Save training plan info and image
            await saveTrainingPlanInfo()
            if trainingPlanImage != nil {
                await saveTrainingPlanImage()
            }
            
        case .sports:
            // Save sports selections
            await saveSportsSelection()
            
        case .goals:
            // Save goals selections
            await saveGoalsSelection()
            
        case .healthKit:
            // HealthKit data is already saved when the step is completed
            break
        }
    }
    
    /// Loads existing user selections from the database for the current step
    func loadExistingSelectionsForCurrentStep() async {
        guard let appState = appState,
              let userId = appState.authService.user?.id.uuidString else { return }
        
        switch currentStep {
        case .equipment:
            await loadExistingEquipmentSelections(userId: userId)
            
        case .injuries:
            await loadExistingInjurySelections(userId: userId)
            
        case .sports:
            await loadExistingSportsSelections(userId: userId)
            
        case .goals:
            await loadExistingGoalsSelections(userId: userId)
            
        case .trainingPlan:
            await loadExistingTrainingPlanData(userId: userId)
            
        case .basicInfo, .healthKit:
            // These are handled separately
            break
        }
    }
    
    /// Loads existing equipment selections from database
    private func loadExistingEquipmentSelections(userId: String) async {
        guard let appState = appState else { return }
        
        // Only load from database if user hasn't made any current selections
        if selectedEquipment.isEmpty {
            do {
                let equipmentIds = try await appState.profileService.getUserEquipment(profileId: userId)
                await MainActor.run {
                    selectedEquipment = Set(equipmentIds)
                }
            } catch {
                // Handle error silently
            }
        }
    }
    
    /// Loads existing injury selections from database
    private func loadExistingInjurySelections(userId: String) async {
        guard let appState = appState else { return }
        
        // Only load from database if user hasn't made any current selections
        if selectedInjuries.isEmpty && otherInjuryText.isEmpty {
            do {
                let userInjuries = try await appState.profileService.getUserInjuries(profileId: userId)
                await MainActor.run {
                    // Load injury IDs
                    let injuryIds = userInjuries.compactMap { $0.injuryId }
                    selectedInjuries = Set(injuryIds)
                    
                    // Load other injury text from the "Other" injury (ID 9)
                    if let otherInjury = userInjuries.first(where: { $0.injuryId == 9 && $0.otherInjuryText != nil }) {
                        otherInjuryText = otherInjury.otherInjuryText ?? ""
                    }
                }
            } catch {
                // Handle error silently
            }
        }
    }
    
    /// Loads existing sports selections from database
    private func loadExistingSportsSelections(userId: String) async {
        guard let appState = appState else { return }
        
        // Only load from database if user hasn't made any current selections
        if selectedSports.isEmpty {
            do {
                let sportIds = try await appState.profileService.getUserSports(profileId: userId)
                await MainActor.run {
                    selectedSports = Set(sportIds)
                }
            } catch {
                // Handle error silently
            }
        }
    }
    
    /// Loads existing goals selections from database
    private func loadExistingGoalsSelections(userId: String) async {
        guard let appState = appState else { return }
        
        // Only load from database if user hasn't made any current selections
        if selectedGoals.isEmpty {
            do {
                let goalIds = try await appState.profileService.getUserGoals(profileId: userId)
                await MainActor.run {
                    selectedGoals = Set(goalIds)
                }
            } catch {
                // Handle error silently
            }
        }
    }
    
    /// Loads existing training plan data from database
    private func loadExistingTrainingPlanData(userId: String) async {
        guard let appState = appState else { return }
        
        // Only load from database if user hasn't made any current selections
        if trainingPlanInfo.isEmpty && !hasTrainingPlan {
            do {
                let profile = try await appState.profileService.getProfile(userId: userId)
                await MainActor.run {
                    hasTrainingPlan = profile.trainingPlanInfo != nil || profile.trainingPlanImageURL != nil
                    trainingPlanInfo = profile.trainingPlanInfo ?? ""
                    // Note: trainingPlanImage would need to be loaded from storage if needed
                }
            } catch {
                // Handle error silently
            }
        }
    }
    
    /// Dismisses the keyboard
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /// Populates physical data from HealthKit and database if available
    func populateHealthKitDataIfAvailable() async {
        guard let appState = appState else { return }
        
        // First, ensure HealthKit data is fetched if authorized
        if appState.healthKitService.isAuthorized {
            await appState.healthKitService.fetchTodayHealthData()
        }
        
        // First try to load from database (this includes data written from previous steps)
        if let userId = appState.authService.user?.id.uuidString,
           let profile = try? await appState.profileService.getProfile(userId: userId) {
            
            await MainActor.run {
                // Populate name fields from database (prioritize database over empty fields)
                if !profile.firstName.isEmpty {
                    firstName = profile.firstName
                }
                if !profile.lastName.isEmpty {
                    lastName = profile.lastName
                }
            
                // Populate height from database
                if let heightCm = profile.heightCm {
                    let inches = heightCm / 2.54
                    let feet = Int(inches / 12.0)
                    let remInches = Int((inches - Double(feet) * 12.0).rounded())
                    heightFeet = String(max(0, feet))
                    heightInches = String(max(0, min(remInches, 11)))
                }
                
                // Populate weight from database
                if let weightKg = profile.weightKg {
                    let weightLbs = Int((weightKg * 2.20462).rounded())
                    weight = String(weightLbs)
                }
                
                // Populate sex from database
                if let profileSex = profile.sex {
                    sex = profileSex
                }
                
                // Populate date of birth from database
                if let profileDob = profile.dateOfBirth {
                    dateOfBirth = profileDob
                }
            }
        }
        
        // Only fall back to HealthKit if database fields are still empty
        Task {
            if heightFeet.isEmpty && heightInches.isEmpty,
               let heightM = appState.healthKitService.healthData?.height {
                let heightCm = heightM * 100.0
                let feet = Int(heightCm / 30.48)
                let inches = Int((heightCm.truncatingRemainder(dividingBy: 30.48)) / 2.54)
                
                await MainActor.run {
                    heightFeet = String(feet)
                    heightInches = String(inches)
                }
            }
            
            if weight.isEmpty,
               let weightKg = appState.healthKitService.healthData?.weight {
                let weightLbs = Int(weightKg * 2.20462)
                await MainActor.run {
                    weight = String(weightLbs)
                }
            }
            
            // Fix: Check if sex is nil AND we can get it from HealthKit
            if sex == nil {
                if let healthKitSex = appState.healthKitService.getBiologicalSex() {
                    await MainActor.run {
                        switch healthKitSex {
                        case .female:
                            sex = .female
                        case .male:
                            sex = .male
                        case .other:
                            sex = .other
                        case .notSet:
                            break
                        @unknown default:
                            break
                        }
                    }
                }
            }
            
            // Fix: Check if dateOfBirth is nil AND we can get it from HealthKit
            if dateOfBirth == nil {
                if let dob = appState.healthKitService.getDateOfBirth() {
                    await MainActor.run {
                        dateOfBirth = dob
                    }
                }
            }
        }
    }
}

