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
            
            print("🔍 HealthKitService: Requesting authorization...")
            print("🔍 HealthKitService: Read types count: \(readTypes.count)")
            print("🔍 HealthKitService: Write types count: \(writeTypes.count)")
            
            // Debug: Print each read type being requested
            print("🔍 HealthKitService: Read types being requested:")
            for readType in readTypes {
                print("   - \(readType.identifier)")
            }
            
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
            
            // Re-check authorization status after request
            print("🔍 HealthKitService: Checking authorization status after request...")
            for readType in readTypes {
                let status = healthStore.authorizationStatus(for: readType)
                print("🔍 HealthKitService: \(readType.identifier) status: \(authorizationStatusString(status))")
            }
            
            // Update the overall authorization status
            checkAuthorizationStatus()
            
            self.isAuthorized = true
            print("🔍 HealthKitService: Authorization successful, fetching health data...")
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
            print("❌ HealthKitService: No user ID available for profile upsert")
            return 
        }
        
        print("🔍 HealthKitService: Starting profile upsert for user: \(userId)")
        
        do {
            // Try to get existing profile
            var profile: UserProfile
            if let existing = try? await appState.profileService.getProfile(userId: userId) {
                print("🔍 HealthKitService: Found existing profile")
                profile = existing
            } else {
                print("🔍 HealthKitService: Creating new profile")
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
            print("🔍 HealthKitService: Writing health data to profile...")
            print("   - healthData exists: \(self.healthData != nil)")
            print("   - healthData?.height: \(self.healthData?.height?.description ?? "nil")")
            print("   - healthData?.weight: \(self.healthData?.weight?.description ?? "nil")")
            print("   - Current profile.heightCm: \(profile.heightCm?.description ?? "nil")")
            print("   - Current profile.weightKg: \(profile.weightKg?.description ?? "nil")")
            
            if let heightM = self.healthData?.height { 
                let heightCm = heightM * 100.0
                profile.heightCm = heightCm
                print("🔍 HealthKitService: Set profile.heightCm to: \(heightCm) cm (from \(heightM) m)")
            } else {
                print("🔍 HealthKitService: No height data available in healthData")
            }
            
            if let weightKg = self.healthData?.weight { 
                profile.weightKg = weightKg
                print("🔍 HealthKitService: Set profile.weightKg to: \(weightKg) kg")
            } else {
                print("🔍 HealthKitService: No weight data available in healthData")
            }
            
            // Get date of birth from HealthKit
            print("🔍 HealthKitService: Fetching date of birth...")
            if let dob = getDateOfBirth() {
                profile.dateOfBirth = dob
                let comps = Calendar.current.dateComponents([.year], from: dob, to: Date())
                profile.age = comps.year
                print("🔍 HealthKitService: Set date of birth: \(dob), age: \(comps.year ?? -1)")
            } else {
                print("🔍 HealthKitService: No date of birth available")
            }
            
            // Get biological sex from HealthKit
            print("🔍 HealthKitService: Fetching biological sex...")
            if let sex = getBiologicalSex() {
                switch sex {
                case .female: 
                    profile.sex = .female
                    print("🔍 HealthKitService: Set sex to female")
                case .male: 
                    profile.sex = .male
                    print("🔍 HealthKitService: Set sex to male")
                case .other: 
                    profile.sex = .other
                    print("🔍 HealthKitService: Set sex to other")
                case .notSet: 
                    print("🔍 HealthKitService: Sex not set")
                    break
                @unknown default: 
                    print("🔍 HealthKitService: Unknown sex value")
                    break
                }
            } else {
                print("🔍 HealthKitService: No biological sex available")
            }
            
            profile.updatedAt = Date()
            
            print("🔍 HealthKitService: Final profile values:")
            print("   - heightCm: \(profile.heightCm?.description ?? "nil")")
            print("   - weightKg: \(profile.weightKg?.description ?? "nil")")
            print("   - dateOfBirth: \(profile.dateOfBirth?.description ?? "nil")")
            print("   - sex: \(profile.sex?.rawValue ?? "nil")")

            // Upsert
            if (try? await appState.profileService.getProfile(userId: userId)) != nil {
                print("🔍 HealthKitService: Updating existing profile...")
                try await appState.profileService.updateProfile(profile)
                print("✅ HealthKitService: Profile updated successfully")
            } else {
                print("🔍 HealthKitService: Creating new profile...")
                try await appState.profileService.createProfile(profile)
                print("✅ HealthKitService: Profile created successfully")
            }
        } catch {
            print("❌ HealthKitService: Failed to save HealthKit data to profile: \(error.localizedDescription)")
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
    
    func fetchTodayHealthData() async {
        guard isAuthorized else { 
            print("❌ HealthKitService: Not authorized, skipping health data fetch")
            return 
        }
        
        print("🔍 HealthKitService: Starting to fetch health data...")
        
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
        print("🔍 HealthKitService: Fetching steps...")
        do {
            steps = try await fetchSteps(from: startOfDay, to: endOfDay)
        } catch {
            print("⚠️ HealthKitService: Failed to fetch steps: \(error.localizedDescription)")
        }
        
        print("🔍 HealthKitService: Fetching active energy...")
        do {
            activeEnergy = try await fetchActiveEnergy(from: startOfDay, to: endOfDay)
        } catch {
            print("⚠️ HealthKitService: Failed to fetch active energy: \(error.localizedDescription)")
        }
        
        print("🔍 HealthKitService: Fetching heart rate...")
        do {
            heartRate = try await fetchHeartRate(from: startOfDay, to: endOfDay)
        } catch {
            print("⚠️ HealthKitService: Failed to fetch heart rate: \(error.localizedDescription)")
        }
        
        print("🔍 HealthKitService: Fetching weight...")
        do {
            weight = try await fetchWeight()
        } catch {
            print("⚠️ HealthKitService: Failed to fetch weight: \(error.localizedDescription)")
        }
        
        print("🔍 HealthKitService: Fetching height...")
        do {
            height = try await fetchHeight()
        } catch {
            print("⚠️ HealthKitService: Failed to fetch height: \(error.localizedDescription)")
        }
        
        print("🔍 HealthKitService: Fetched data summary:")
        print("   - Steps: \(steps)")
        print("   - Active Energy: \(activeEnergy)")
        print("   - Heart Rate: \(heartRate?.description ?? "nil")")
        print("   - Weight: \(weight?.description ?? "nil") kg")
        print("   - Height: \(height?.description ?? "nil") m")
        
        healthData = HealthData(
            steps: steps,
            activeEnergy: activeEnergy,
            heartRate: heartRate,
            weight: weight,
            height: height,
            date: now
        )
        
        print("✅ HealthKitService: Successfully created healthData object")
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
        print("🔍 HealthKitService: Fetching weight...")
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            print("❌ HealthKitService: bodyMass type not available")
            throw HealthKitError.unsupportedType
        }
        
        // Check authorization status
        let authStatus = healthStore.authorizationStatus(for: type)
        print("🔍 HealthKitService: Weight authorization status: \(authorizationStatusString(authStatus))")
        
        // Try to read the data even if authorization status shows as denied
        // Sometimes there's a timing issue with the authorization status
        let unit = HKUnit.gramUnit(with: .kilo) // kg
        
        do {
            let weight = try await fetchMostRecentQuantitySample(for: type, unit: unit)
            print("🔍 HealthKitService: Fetched weight: \(weight?.description ?? "nil") kg")
            return weight
        } catch {
            print("❌ HealthKitService: Failed to fetch weight: \(error.localizedDescription)")
            
            // If authorization was denied, try requesting it again
            if authStatus == .sharingDenied {
                print("🔍 HealthKitService: Weight authorization denied, requesting again...")
                try await healthStore.requestAuthorization(toShare: [], read: [type])
                // Add a small delay
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                // Try again after requesting authorization
                let weight = try await fetchMostRecentQuantitySample(for: type, unit: unit)
                print("🔍 HealthKitService: Fetched weight after re-authorization: \(weight?.description ?? "nil") kg")
                return weight
            }
            
            return nil
        }
    }

    public func fetchHeight() async throws -> Double? {
        print("🔍 HealthKitService: Fetching height...")
        guard let type = HKQuantityType.quantityType(forIdentifier: .height) else {
            print("❌ HealthKitService: height type not available")
            throw HealthKitError.unsupportedType
        }
        
        // Check authorization status
        let authStatus = healthStore.authorizationStatus(for: type)
        print("🔍 HealthKitService: Height authorization status: \(authorizationStatusString(authStatus))")
        
        // Try to read the data even if authorization status shows as denied
        // Sometimes there's a timing issue with the authorization status
        let unit = HKUnit.meter()
        
        do {
            let height = try await fetchMostRecentQuantitySample(for: type, unit: unit)
            print("🔍 HealthKitService: Fetched height: \(height?.description ?? "nil") meters")
            return height
        } catch {
            print("❌ HealthKitService: Failed to fetch height: \(error.localizedDescription)")
            
            // If authorization was denied, try requesting it again
            if authStatus == .sharingDenied {
                print("🔍 HealthKitService: Height authorization denied, requesting again...")
                try await healthStore.requestAuthorization(toShare: [], read: [type])
                // Add a small delay
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                // Try again after requesting authorization
                let height = try await fetchMostRecentQuantitySample(for: type, unit: unit)
                print("🔍 HealthKitService: Fetched height after re-authorization: \(height?.description ?? "nil") meters")
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
                    print("❌ HealthKitService: Error fetching sample: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                
                print("🔍 HealthKitService: Found \(samples?.count ?? 0) samples")
                
                guard let quantitySample = samples?.first as? HKQuantitySample else {
                    print("🔍 HealthKitService: No samples found or first sample is not HKQuantitySample")
                    continuation.resume(returning: nil)
                    return
                }
                
                let value = quantitySample.quantity.doubleValue(for: unit)
                print("🔍 HealthKitService: Sample value: \(value) (unit: \(unit))")
                print("🔍 HealthKitService: Sample date: \(quantitySample.startDate)")
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
        print("🔍 HealthKitService: Debug - Authorization Status Check")
        
        let readTypes = Config.healthKitReadTypes
        for readType in readTypes {
            let status = healthStore.authorizationStatus(for: readType)
            print("   - \(readType.identifier): \(authorizationStatusString(status))")
        }
        
        print("🔍 HealthKitService: Debug - Current healthData state:")
        print("   - healthData exists: \(self.healthData != nil)")
        print("   - healthData?.weight: \(self.healthData?.weight?.description ?? "nil")")
        print("   - healthData?.height: \(self.healthData?.height?.description ?? "nil")")
        print("   - healthData?.steps: \(self.healthData?.steps ?? -1)")
        print("   - healthData?.activeEnergy: \(self.healthData?.activeEnergy ?? -1)")
        print("   - healthData?.heartRate: \(self.healthData?.heartRate?.description ?? "nil")")
    }
    
    /// Force refresh health data (useful for debugging)
    func forceRefreshHealthData() async {
        print("🔍 HealthKitService: Force refreshing health data...")
        
        // First check authorization status
        debugAuthorizationStatus()
        
        // Try to fetch data again
        await fetchTodayHealthData()
        
        // Check the results
        print("🔍 HealthKitService: After force refresh:")
        print("   - healthData exists: \(self.healthData != nil)")
        print("   - healthData?.weight: \(self.healthData?.weight?.description ?? "nil")")
        print("   - healthData?.height: \(self.healthData?.height?.description ?? "nil")")
    }
}

enum HealthKitError: Error {
    case unsupportedType
    case noData
    case authorizationDenied
}
