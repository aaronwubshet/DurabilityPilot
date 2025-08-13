import Foundation

// MARK: - Health Data
struct HealthData: Codable {
    let steps: Int
    let activeEnergy: Double
    let heartRate: Double?
    let weight: Double?
    let height: Double?
    let date: Date
}

