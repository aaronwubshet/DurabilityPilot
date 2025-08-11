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
    @Published var errorMessage: String?
    
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
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year ?? 0
    }
    
    var canProceed: Bool {
        switch currentStep {
        case .basicInfo:
            return !firstName.isEmpty && !lastName.isEmpty && calculatedAge > 0
        case .equipment:
            return true // Allow proceeding even if no equipment selected
        case .injuries:
            return true // Always can proceed
        case .trainingPlan:
            return true // Always can proceed
        case .sports:
            return !selectedSports.isEmpty
        case .goals:
            return !selectedGoals.isEmpty
        case .healthKit:
            return true // Always can proceed
        }
    }
    
    func nextStep() {
        if currentStep.rawValue < OnboardingStep.allCases.count - 1 {
            currentStep = OnboardingStep(rawValue: currentStep.rawValue + 1)!
        }
    }
    
    func previousStep() {
        if currentStep.rawValue > 0 {
            currentStep = OnboardingStep(rawValue: currentStep.rawValue - 1)!
        }
    }
    
    func completeOnboarding(appState: AppState) async {
        isLoading = true
        defer { isLoading = false }
        
        var imageURL: String?
        if let image = trainingPlanImage {
            do {
                imageURL = try await appState.storageService.uploadImage(
                    from: image.jpegData(compressionQuality: 0.8),
                    bucket: "training-plan-images"
                )
            } catch {
                errorMessage = "Failed to upload image: \(error.localizedDescription)"
            }
        }
        
        let profile = UserProfile(
            id: appState.authService.user?.id.uuidString ?? "",
            firstName: firstName,
            lastName: lastName,
            email: appState.authService.user?.email ?? "",
            age: calculatedAge,
            sex: sex,
            heightCm: convertHeightToCm(),
            weightKg: Double(weight),
            isPilot: false,
            onboardingCompleted: true,
            assessmentCompleted: false,
            trainingPlanInfo: hasTrainingPlan ? trainingPlanInfo : nil,
            trainingPlanImageURL: imageURL,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try await appState.profileService.createProfile(profile)
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
        }
        // Advance app state regardless to keep the flow moving into assessment
        appState.onboardingCompleted = true
    }
    
    private func convertHeightToCm() -> Double? {
        guard let feet = Double(heightFeet), let inches = Double(heightInches) else { return nil }
        return (feet * 30.48) + (inches * 2.54)
    }
    
    
}

