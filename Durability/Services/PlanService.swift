import Foundation
import Supabase

@MainActor
class PlanService: ObservableObject {
    private let supabase = SupabaseManager.shared.client
    
    func generatePlan(profileId: String) async throws -> Plan {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 42, to: startDate)!
        
        let plan = Plan(
            id: UUID().uuidString,
            profileId: profileId,
            startDate: startDate,
            endDate: endDate,
            createdAt: Date(),
            phases: []
        )
        
        // Create the plan in database
        try await supabase
            .from("plans")
            .insert(plan)
            .execute()
        
        // Generate phases
        let phases = try await generatePhases(planId: plan.id, startDate: startDate, endDate: endDate)
        
        var updatedPlan = plan
        updatedPlan.phases = phases
        
        return updatedPlan
    }
    
    private func generatePhases(planId: String, startDate: Date, endDate: Date) async throws -> [PlanPhase] {
        var phases: [PlanPhase] = []
        
        for phaseNumber in 1...3 {
            let phaseStartDate = Calendar.current.date(byAdding: .day, value: (phaseNumber - 1) * 14, to: startDate)!
            let phaseEndDate = Calendar.current.date(byAdding: .day, value: 14, to: phaseStartDate)!
            
            let weights = getPhaseWeights(phaseNumber: phaseNumber)
            
            let phase = PlanPhase(
                id: UUID().uuidString,
                planId: planId,
                phaseNumber: phaseNumber,
                recoveryWeight: weights.recovery,
                resilienceWeight: weights.resilience,
                resultsWeight: weights.results,
                startDate: phaseStartDate,
                endDate: phaseEndDate,
                dailyWorkouts: []
            )
            
            // Create phase in database
            try await supabase
                .from("plan_phases")
                .insert(phase)
                .execute()
            
            // Generate daily workouts for this phase
            let workouts = try await generateDailyWorkouts(phaseId: phase.id, startDate: phaseStartDate, endDate: phaseEndDate)
            
            var updatedPhase = phase
            updatedPhase.dailyWorkouts = workouts
            phases.append(updatedPhase)
        }
        
        return phases
    }
    
    private func getPhaseWeights(phaseNumber: Int) -> (recovery: Double, resilience: Double, results: Double) {
        switch phaseNumber {
        case 1:
            return (recovery: 0.5, resilience: 0.3, results: 0.2)
        case 2:
            return (recovery: 0.15, resilience: 0.6, results: 0.25)
        case 3:
            return (recovery: 0.05, resilience: 0.25, results: 0.7)
        default:
            return (recovery: 0.33, resilience: 0.33, results: 0.34)
        }
    }
    
    private func generateDailyWorkouts(phaseId: String, startDate: Date, endDate: Date) async throws -> [DailyWorkout] {
        var workouts: [DailyWorkout] = []
        let calendar = Calendar.current
        
        var currentDate = startDate
        while currentDate < endDate {
            let workout = DailyWorkout(
                id: UUID().uuidString,
                planPhaseId: phaseId,
                workoutDate: currentDate,
                status: .pending,
                movements: []
            )
            
            // Create workout in database
            try await supabase
                .from("daily_workouts")
                .insert(workout)
                .execute()
            
            // Generate movements for this workout
            let movements = try await generateWorkoutMovements(workoutId: workout.id)
            
            var updatedWorkout = workout
            updatedWorkout.movements = movements
            workouts.append(updatedWorkout)
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return workouts
    }
    
    private func generateWorkoutMovements(workoutId: String) async throws -> [DailyWorkoutMovement] {
        // For now, generate 3-6 random movements
        let movementCount = Int.random(in: 3...6)
        var movements: [DailyWorkoutMovement] = []
        
        let availableMovements = getAvailableMovements()
        
        for i in 0..<movementCount {
            let randomMovement = availableMovements.randomElement()!
            
            let movement = DailyWorkoutMovement(
                id: UUID().uuidString,
                dailyWorkoutId: workoutId,
                movementId: randomMovement.id,
                sequence: i + 1,
                status: .pending,
                assignedIntensity: Intensity(reps: 10, sets: 3),
                recoveryImpactScore: randomMovement.recoveryImpactScore,
                resilienceImpactScore: randomMovement.resilienceImpactScore,
                resultsImpactScore: randomMovement.resultsImpactScore
            )
            
            // Create movement in database
            try await supabase
                .from("daily_workout_movements")
                .insert(movement)
                .execute()
            
            movements.append(movement)
        }
        
        return movements
    }
    
    private func getAvailableMovements() -> [Movement] {
        // Return a list of available movements
        return [
            Movement(id: 1, name: "Squat", description: "Basic squat movement", videoURL: nil, jointsImpacted: ["ankle", "knee", "hip"], musclesImpacted: ["quad", "glute"], superMetricsImpacted: ["functional_strength"], sportsImpacted: ["Soccer", "Basketball"], intensityOptions: ["reps", "weight"], recoveryImpactScore: 0.3, resilienceImpactScore: 0.7, resultsImpactScore: 0.8),
            Movement(id: 2, name: "Deadlift", description: "Hip hinge movement", videoURL: nil, jointsImpacted: ["hip", "knee"], musclesImpacted: ["hamstring", "glute"], superMetricsImpacted: ["functional_strength"], sportsImpacted: ["Football"], intensityOptions: ["reps", "weight"], recoveryImpactScore: 0.2, resilienceImpactScore: 0.8, resultsImpactScore: 0.9),
            Movement(id: 3, name: "Rest", description: "Active recovery", videoURL: nil, jointsImpacted: [], musclesImpacted: [], superMetricsImpacted: [], sportsImpacted: [], intensityOptions: [], recoveryImpactScore: 0.9, resilienceImpactScore: 0.1, resultsImpactScore: 0.1),
            Movement(id: 4, name: "Walk", description: "Low intensity cardio", videoURL: nil, jointsImpacted: ["ankle", "knee", "hip"], musclesImpacted: ["quad", "hamstring"], superMetricsImpacted: ["aerobic_capacity"], sportsImpacted: ["Running"], intensityOptions: ["distance", "time"], recoveryImpactScore: 0.7, resilienceImpactScore: 0.3, resultsImpactScore: 0.2)
        ]
    }
    
    func getCurrentPlan(profileId: String) async throws -> Plan? {
        let response: [Plan] = try await supabase
            .from("plans")
            .select("*")
            .eq("profile_id", value: profileId)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        
        guard let plan = response.first else { return nil }
        
        // Load phases and workouts
        let phases = try await getPlanPhases(planId: plan.id)
        
        var updatedPlan = plan
        updatedPlan.phases = phases
        
        return updatedPlan
    }
    
    private func getPlanPhases(planId: String) async throws -> [PlanPhase] {
        let response: [PlanPhase] = try await supabase
            .from("plan_phases")
            .select("*")
            .eq("plan_id", value: planId)
            .order("phase_number", ascending: true)
            .execute()
            .value
        
        var phases: [PlanPhase] = []
        for phase in response {
            let workouts = try await getDailyWorkouts(phaseId: phase.id)
            var updatedPhase = phase
            updatedPhase.dailyWorkouts = workouts
            phases.append(updatedPhase)
        }
        
        return phases
    }
    
    private func getDailyWorkouts(phaseId: String) async throws -> [DailyWorkout] {
        let response: [DailyWorkout] = try await supabase
            .from("daily_workouts")
            .select("*")
            .eq("plan_phase_id", value: phaseId)
            .order("workout_date", ascending: true)
            .execute()
            .value
        
        var workouts: [DailyWorkout] = []
        for workout in response {
            let movements = try await getWorkoutMovements(workoutId: workout.id)
            var updatedWorkout = workout
            updatedWorkout.movements = movements
            workouts.append(updatedWorkout)
        }
        
        return workouts
    }
    
    private func getWorkoutMovements(workoutId: String) async throws -> [DailyWorkoutMovement] {
        let response: [DailyWorkoutMovement] = try await supabase
            .from("daily_workout_movements")
            .select("*")
            .eq("daily_workout_id", value: workoutId)
            .order("sequence", ascending: true)
            .execute()
            .value
        
        return response
    }

    // MARK: - Updates & Queries
    func updateMovementStatus(movementId: String, status: DailyWorkoutMovement.MovementStatus) async throws {
        try await supabase
            .from("daily_workout_movements")
            .update(["status": status.rawValue])
            .eq("id", value: movementId)
            .execute()
    }
    
    func updateWorkoutStatus(workoutId: String, status: DailyWorkout.WorkoutStatus) async throws {
        try await supabase
            .from("daily_workouts")
            .update(["status": status.rawValue])
            .eq("id", value: workoutId)
            .execute()
    }
    
    func countCompletedWorkouts(profileId: String, since: Date) async throws -> Int {
        // Find the current plan and count completed workouts since a date
        guard let plan = try await getCurrentPlan(profileId: profileId) else { return 0 }
        let phases = try await getPlanPhases(planId: plan.id)
        var count = 0
        for phase in phases {
            let workouts: [DailyWorkout] = try await supabase
                .from("daily_workouts")
                .select("*")
                .eq("plan_phase_id", value: phase.id)
                .gte("workout_date", value: ISO8601DateFormatter().string(from: since))
                .eq("status", value: DailyWorkout.WorkoutStatus.completed.rawValue)
                .execute()
                .value
            count += workouts.count
        }
        return count
    }
}
