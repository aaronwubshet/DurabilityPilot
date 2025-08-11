import Foundation
import HealthKit

enum Config {
    // Supabase Configuration
    static let supabaseURL = URL(string: "https://atvnjpwmydhqbxjgczti.supabase.co")!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0dm5qcHdteWRocWJ4amdjenRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ0NTUxMTAsImV4cCI6MjA3MDAzMTExMH0.9EAsCCf9kC5GreyOXJv0b0K4zH08jT14jaG-omzf2ww"
    
    // Apple Sign In Configuration
    
    static let appleSignInBundleId = "ai.mydurability.Durability"
    
    // App Configuration
    static let appName = "Durability"
    static let appVersion = "1.0.0"
    
    // Assessment Configuration
    static let maxAssessmentVideoDuration: TimeInterval = 180 // 3 minutes
    static let maxImageUploadSize: Int64 = 10 * 1024 * 1024 // 10MB
    
    // Plan Configuration
    static let defaultPlanDuration = 42 // 6 weeks
    static let defaultWorkoutDuration = 30 // minutes
    
    // HealthKit Configuration
    static let healthKitReadTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .height)!,
        HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
        HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
    ]
    
    static let healthKitWriteTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!
    ]
}

