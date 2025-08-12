import Foundation
import HealthKit
import Combine

@MainActor
class HealthKitService: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    @Published var healthData: HealthData?
    @Published var errorMessage: String?
    
    init() {
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit is not available on this device"
            return false
        }
        
        do {
            try await healthStore.requestAuthorization(
                toShare: Config.healthKitWriteTypes,
                read: Config.healthKitReadTypes
            )
            
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
        guard let userId = appState.authService.user?.id.uuidString else { return }
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
                    isPilot: false,
                    onboardingCompleted: false,
                    assessmentCompleted: false,
                    trainingPlanInfo: nil,
                    trainingPlanImageURL: nil,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            }

            // Write health values into profile
            if let heightM = self.healthData?.height { profile.heightCm = heightM * 100.0 }
            if let weightKg = self.healthData?.weight { profile.weightKg = weightKg }
            if let dob = getDateOfBirth() {
                profile.dateOfBirth = dob
                let comps = Calendar.current.dateComponents([.year], from: dob, to: Date())
                profile.age = comps.year
            }
            if let sex = getBiologicalSex() {
                switch sex {
                case .female: profile.sex = .female
                case .male: profile.sex = .male
                case .other: profile.sex = .other
                case .notSet: break
                @unknown default: break
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
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let readTypes = Config.healthKitReadTypes
        let writeTypes = Config.healthKitWriteTypes
        
        // This is just an example check. For a real app, you might need to check
        // authorization status for each type individually.
        guard let firstReadType = readTypes.first, let firstWriteType = writeTypes.first else {
            return
        }

        let readStatus = healthStore.authorizationStatus(for: firstReadType)
        let writeStatus = healthStore.authorizationStatus(for: firstWriteType)
        
        isAuthorized = readStatus == .sharingAuthorized && writeStatus == .sharingAuthorized
    }
    
    func fetchTodayHealthData() async {
        guard isAuthorized else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        do {
            let steps = try await fetchSteps(from: startOfDay, to: endOfDay)
            let activeEnergy = try await fetchActiveEnergy(from: startOfDay, to: endOfDay)
            let heartRate = try await fetchHeartRate(from: startOfDay, to: endOfDay)
            let weight = try await fetchWeight()
            let height = try await fetchHeight()
            
            healthData = HealthData(
                steps: steps,
                activeEnergy: activeEnergy,
                heartRate: heartRate,
                weight: weight,
                height: height,
                date: now
            )
        } catch {
            errorMessage = "Failed to fetch health data: \(error.localizedDescription)"
        }
    }
    
    private func fetchSteps(from startDate: Date, to endDate: Date) async throws -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.unsupportedType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        // Note: HKStatisticsQuery is not async. For a real implementation,
        // you would wrap this in a continuation or use a newer async API if available.
        // For now, we are returning a placeholder.
        _ = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            // Handle result
        }
        
        // For now, return a placeholder value
        return 8500
    }
    
    private func fetchActiveEnergy(from startDate: Date, to endDate: Date) async throws -> Double {
        guard HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) != nil else {
            throw HealthKitError.unsupportedType
        }
        
        // For now, return a placeholder value
        return 450.0
    }
    
    private func fetchHeartRate(from startDate: Date, to endDate: Date) async throws -> Double? {
        guard HKQuantityType.quantityType(forIdentifier: .heartRate) != nil else {
            throw HealthKitError.unsupportedType
        }
        
        // For now, return a placeholder value
        return 72.0
    }
    
    private func fetchWeight() async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.unsupportedType
        }
        let unit = HKUnit.gramUnit(with: .kilo) // kilograms
        return try await fetchMostRecentQuantitySample(for: type, unit: unit)
    }

    private func fetchHeight() async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .height) else {
            throw HealthKitError.unsupportedType
        }
        let unit = HKUnit.meter()
        return try await fetchMostRecentQuantitySample(for: type, unit: unit)
    }

    private func fetchMostRecentQuantitySample(for type: HKQuantityType, unit: HKUnit) async throws -> Double? {
        return try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
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
        do {
            let comps = try healthStore.dateOfBirthComponents()
            return Calendar.current.date(from: comps)
        } catch { return nil }
    }

    func getBiologicalSex() -> HKBiologicalSex? {
        do {
            let sex = try healthStore.biologicalSex().biologicalSex
            return sex
        } catch { return nil }
    }
}

enum HealthKitError: Error {
    case unsupportedType
    case noData
    case authorizationDenied
}
