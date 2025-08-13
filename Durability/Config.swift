import Foundation
import HealthKit
import SwiftUI // Added for Color

// MARK: - App Configuration
struct Config {
    // Supabase Configuration
    static let supabaseURL: URL = {
        if let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"] {
            return URL(string: urlString)!
        }
        return URL(string: "https://atvnjpwmydhqbxjgczti.supabase.co")!
    }()
    
    static let supabaseAnonKey: String = {
        if let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] {
            return key
        }
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0dm5qcHdteWRocWJ4amdjenRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ0NTUxMTAsImV4cCI6MjA3MDAzMTExMH0.9EAsCCf9kC5GreyOXJv0b0K4zH08jT14jaG-omzf2ww"
    }()
    
    // App Version
    static let appVersion = "1.0.0"
    
    // Assessment Configuration
    static let maxAssessmentDuration: TimeInterval = 180 // 3 minutes
    
    // Storage Configuration (Private Buckets)
    // IMPORTANT: These buckets must be configured as PRIVATE in Supabase
    // - Files are not publicly accessible
    // - Access is controlled through signed URLs
    // - User isolation through folder structure (profileId/...)
    static let assessmentVideosBucket = "assessment-videos" // Private bucket for assessment videos
    static let trainingPlanImagesBucket = "training-plan-images" // Private bucket for training plan images
    
    // HealthKit Types
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
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
    ]
}

// MARK: - Custom Color Scheme
extension Color {
    // Dark Space Grey Color Scheme
    static let darkSpaceGrey = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let darkerSpaceGrey = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let lightSpaceGrey = Color(red: 0.18, green: 0.18, blue: 0.20)
    
    // Text Colors
    static let lightText = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let secondaryText = Color(red: 0.7, green: 0.7, blue: 0.75)
    
    // Accent Colors (keeping your electric green)
    static let electricGreen = Color(red: 0.043, green: 0.847, blue: 0.0)
    static let brightGreen = Color(red: 0.2, green: 0.9, blue: 0.2)
}

