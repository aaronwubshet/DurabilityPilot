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

// MARK: - Progress Tracking
struct ProgressData: Codable {
    let date: Date
    let durabilityScore: Double
    let superMetrics: SuperMetrics
}

struct SuperMetrics: Codable {
    let rangeOfMotion: Double
    let flexibility: Double
    let mobility: Double
    let functionalStrength: Double
    let aerobicCapacity: Double
    
    var average: Double {
        return (rangeOfMotion + flexibility + mobility + functionalStrength + aerobicCapacity) / 5.0
    }
}

