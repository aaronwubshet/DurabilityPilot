import Foundation
import HealthKit

@MainActor
class HealthKitService: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    @Published var healthData: HealthData?
    @Published var errorMessage: String?
    
    init() {
        checkAuthorizationStatus()
    }
    
    // Helper function to convert authorization status to readable string
    private func authorizationStatusString(_ status: HKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "notDetermined (0)"
        case .sharingDenied:
            return "sharingDenied (1)"
        case .sharingAuthorized:
            return "sharingAuthorized (2)"
        @unknown default:
            return "unknown (\(status.rawValue))"
        }
    }
    
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit is not available on this device"
            return false
        }
        
        do {
            let readTypes = Config.healthKitReadTypes
            let writeTypes = Config.healthKitWriteTypes
            
            // Check if date of birth and biological sex types are included
            let _ = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)
            let _ = HKObjectType.characteristicType(forIdentifier: .biologicalSex)
            
            // Request authorization for all types in a single call
            try await healthStore.requestAuthorization(
                toShare: writeTypes,
                read: readTypes
            )
            
            // Add a small delay to allow iOS to update authorization status
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Update the overall authorization status
            checkAuthorizationStatus()
            
            self.isAuthorized = true
            await fetchTodayHealthData()
            return true
        } catch {
            self.isAuthorized = false
            errorMessage = "Failed to request HealthKit authorization: \(error.localizedDescription)"
            return false
        }
    }

    // Persist fetched profile-related HealthKit values to Supabase profile
    func upsertProfileFromHealthData(appState: AppState) async {
        guard let userId = appState.authService.user?.id.uuidString else { 
            return 
        }
        
        do {
            // Try to get existing profile
            var profile: UserProfile
            if let existing = try? await appState.profileService.getProfile(userId: userId) {
                profile = existing
            } else {
                profile = UserProfile(
                    id: userId,
                    firstName: "",
                    lastName: "",
                    dateOfBirth: nil,
                    age: nil,
                    sex: nil,
                    heightCm: nil,
                    weightKg: nil,
                    isPilot: true,
                    onboardingCompleted: false,
                    assessmentCompleted: false,
                    trainingPlanInfo: nil,
                    trainingPlanImageURL: nil,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            }

            // Write health values into profile
            if let heightM = self.healthData?.height { 
                let heightCm = heightM * 100.0
                profile.heightCm = heightCm
            }
            
            if let weightKg = self.healthData?.weight { 
                profile.weightKg = weightKg
            }
            
            // Get date of birth from HealthKit
            if let dob = getDateOfBirth() {
                profile.dateOfBirth = dob
                let comps = Calendar.current.dateComponents([.year], from: dob, to: Date())
                profile.age = comps.year
            }
            
            // Get biological sex from HealthKit
            if let sex = getBiologicalSex() {
                switch sex {
                case .female: 
                    profile.sex = .female
                case .male: 
                    profile.sex = .male
                case .other: 
                    profile.sex = .other
                case .notSet: 
                    break
                @unknown default: 
                    break
                }
            }
            
            profile.updatedAt = Date()

            // Upsert
            if (try? await appState.profileService.getProfile(userId: userId)) != nil {
                try await appState.profileService.updateProfile(profile)
            } else {
                try await appState.profileService.createProfile(profile)
            }
        } catch {
            self.errorMessage = "Failed to save HealthKit data to profile: \(error.localizedDescription)"
        }
    }
    
    private func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else { 
            return 
        }
        
        let readTypes = Config.healthKitReadTypes
        let writeTypes = Config.healthKitWriteTypes
        
        // Check authorization for all read types
        var allReadAuthorized = true
        for readType in readTypes {
            let status = healthStore.authorizationStatus(for: readType)
            if status != .sharingAuthorized {
                allReadAuthorized = false
            }
        }
        
        // Check authorization for all write types
        var allWriteAuthorized = true
        for writeType in writeTypes {
            let status = healthStore.authorizationStatus(for: writeType)
            if status != .sharingAuthorized {
                allWriteAuthorized = false
            }
        }
        
        isAuthorized = allReadAuthorized && allWriteAuthorized
    }
    
    func updateAuthorizationStatus() {
        checkAuthorizationStatus()
    }
    
    func fetchTodayHealthData() async {
        guard isAuthorized else { 
                    return
    }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Initialize with default values
        var steps = 0
        var activeEnergy = 0.0
        var heartRate: Double? = nil
        var weight: Double? = nil
        var height: Double? = nil
        
        // Fetch each data type individually and handle failures gracefully
        do {
            steps = try await fetchSteps(from: startOfDay, to: endOfDay)
        } catch {
            // Handle error silently
        }
        
        do {
            activeEnergy = try await fetchActiveEnergy(from: startOfDay, to: endOfDay)
        } catch {
            // Handle error silently
        }
        
        do {
            heartRate = try await fetchHeartRate(from: startOfDay, to: endOfDay)
        } catch {
            // Handle error silently
        }
        
        do {
            weight = try await fetchWeight()
        } catch {
            // Handle error silently
        }
        
        do {
            height = try await fetchHeight()
        } catch {
            // Handle error silently
        }
        
        healthData = HealthData(
            steps: steps,
            activeEnergy: activeEnergy,
            heartRate: heartRate,
            weight: weight,
            height: height,
            date: now
        )
        

    }
    
    private func fetchSteps(from startDate: Date, to endDate: Date) async throws -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.unsupportedType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            self.healthStore.execute(query)
        }
    }
    
    private func fetchActiveEnergy(from startDate: Date, to endDate: Date) async throws -> Double {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.unsupportedType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let energy = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                continuation.resume(returning: energy)
            }
            self.healthStore.execute(query)
        }
    }
    
    private func fetchHeartRate(from startDate: Date, to endDate: Date) async throws -> Double? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.unsupportedType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let heartRate = result?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) ?? 0
                continuation.resume(returning: heartRate > 0 ? heartRate : nil)
            }
            self.healthStore.execute(query)
        }
    }
    
    public func fetchWeight() async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.unsupportedType
        }
        
        // Check authorization status
        let authStatus = healthStore.authorizationStatus(for: type)
        
        // Try to read the data even if authorization status shows as denied
        // Sometimes there's a timing issue with the authorization status
        let unit = HKUnit.gramUnit(with: .kilo) // kg
        
        do {
            let weight = try await fetchMostRecentQuantitySample(for: type, unit: unit)
            return weight
        } catch {
            // If authorization was denied, try requesting it again
            if authStatus == .sharingDenied {
                try await healthStore.requestAuthorization(toShare: [], read: [type])
                // Add a small delay
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                // Try again after requesting authorization
                let weight = try await fetchMostRecentQuantitySample(for: type, unit: unit)
                return weight
            }
            
            return nil
        }
    }

    public func fetchHeight() async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .height) else {
            throw HealthKitError.unsupportedType
        }
        
        // Check authorization status
        let authStatus = healthStore.authorizationStatus(for: type)
        
        // Try to read the data even if authorization status shows as denied
        // Sometimes there's a timing issue with the authorization status
        let unit = HKUnit.meter()
        
        do {
            let height = try await fetchMostRecentQuantitySample(for: type, unit: unit)
            return height
        } catch {
            // If authorization was denied, try requesting it again
            if authStatus == .sharingDenied {
                try await healthStore.requestAuthorization(toShare: [], read: [type])
                // Add a small delay
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                // Try again after requesting authorization
                let height = try await fetchMostRecentQuantitySample(for: type, unit: unit)
                return height
            }
            
            return nil
        }
    }

    private func fetchMostRecentQuantitySample(for type: HKQuantityType, unit: HKUnit) async throws -> Double? {
        return try await withCheckedThrowingContinuation { continuation in
            // Use a sort descriptor to get the most recent sample
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let quantitySample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let value = quantitySample.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            self.healthStore.execute(query)
        }
    }

    func getDateOfBirth() -> Date? {
        // Check if we have authorization for date of birth
        guard let dateOfBirthType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) else {
            return nil
        }
        
        let _ = healthStore.authorizationStatus(for: dateOfBirthType)
        
        // Try to read the data even if authorization status shows as denied
        // Sometimes there's a timing issue with the authorization status
        do {
            let comps = try healthStore.dateOfBirthComponents()
            let date = Calendar.current.date(from: comps)
            return date
        } catch {
            return nil
        }
    }

    func getBiologicalSex() -> HKBiologicalSex? {
        // Check if we have authorization for biological sex
        guard let biologicalSexType = HKObjectType.characteristicType(forIdentifier: .biologicalSex) else {
            return nil
        }
        
        let _ = healthStore.authorizationStatus(for: biologicalSexType)
        
        // Try to read the data even if authorization status shows as denied
        // Sometimes there's a timing issue with the authorization status
        do {
            let sex = try healthStore.biologicalSex().biologicalSex
            return sex
        } catch {
            return nil
        }
    }
    
    // MARK: - Debug Methods
    
    /// Debug method to check authorization status for all HealthKit types
    func debugAuthorizationStatus() {
        // Debug functionality removed
    }
    
    /// Force refresh health data (useful for debugging)
    func forceRefreshHealthData() async {
        // Try to fetch data again
        await fetchTodayHealthData()
    }
}

enum HealthKitError: Error {
    case unsupportedType
    case noData
    case authorizationDenied
}
