import Foundation
import Supabase

@MainActor
class PlanService: ObservableObject {
    private let supabase = SupabaseManager.shared.client

    // MARK: - Flexible decoding row types (bypass strict Codable on models)
    private struct PlanRow: Decodable {
        let id: String
        let profile_id: String
        let start_date: String?
        let end_date: String?
        let created_at: String?
    }

    private struct PlanPhaseRow: Decodable {
        let id: String
        let plan_id: String
        let phase_number: Int
        let recovery_weight: Double
        let resilience_weight: Double
        let results_weight: Double
        let start_date: String?
        let end_date: String?
    }

    private struct DailyWorkoutRow: Decodable {
        let id: String
        let plan_phase_id: String
        let workout_date: String?
        let status: String?
    }

    private struct DailyWorkoutMovementRow: Decodable {
        let id: String
        let daily_workout_id: String
        let movement_id: FlexibleInt
        let sequence: Int?
        let status: String?
        let assigned_intensity: IntensityRow?
        let recovery_impact_score: Double?
        let resilience_impact_score: Double?
        let results_impact_score: Double?
    }

    private struct IntensityRow: Decodable {
        let reps: Int?
        let sets: Int?
        let weight_kg: Double?
        let distance_meters: Double?
        let duration_seconds: Int?
        let rpe: Int?
    }

    private enum FlexibleInt: Decodable {
        case int(Int)
        case string(String)

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let i = try? c.decode(Int.self) {
                self = .int(i)
                return
            }
            let s = try c.decode(String.self)
            self = .string(s)
        }

        var intValue: Int {
            switch self {
            case .int(let i): return i
            case .string(let s): return Int(s) ?? 0
            }
        }
    }

    private func parseDateString(_ value: String?) -> Date {
        guard let v = value else { return Date() }
        if let d = Plan.iso8601Formatter.date(from: v) { return d }
        if let d = Plan.dateOnlyFormatter.date(from: v) { return d }
        for fmt in Plan.isoCandidates { if let d = fmt.date(from: v) { return d } }
        return Date()
    }

    private func toArray(_ data: Data?) -> [[String: Any]] {
        guard let d = data else { return [] }
        do {
            let json = try JSONSerialization.jsonObject(with: d, options: [])
            return json as? [[String: Any]] ?? []
        } catch {
            print("[PlanService] JSON parse error: \(error.localizedDescription)")
            return []
        }
    }
    
    private func logArraySummary(label: String, data: [[String: Any]]) {
        let count = data.count
        let keys = data.first.map { Array($0.keys).sorted() } ?? []
        print("[PlanService] \(label): count=\(count) first_keys=\(keys)")
        if count > 0 {
            let sample = data[0]
            let preview = sample.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            print("[PlanService] \(label) sample: { \(preview) }")
        }
    }
    
    private func string(_ dict: [String: Any], _ key: String) -> String? {
        if let s = dict[key] as? String { return s }
        if let n = dict[key] as? NSNumber { return n.stringValue }
        return nil
    }
    private func int(_ dict: [String: Any], _ key: String) -> Int? {
        if let n = dict[key] as? NSNumber { return n.intValue }
        if let s = dict[key] as? String { return Int(s) }
        return nil
    }
    private func double(_ dict: [String: Any], _ key: String) -> Double? {
        if let n = dict[key] as? NSNumber { return n.doubleValue }
        if let s = dict[key] as? String { return Double(s) }
        return nil
    }
    
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
        
        let availableMovements = await getAvailableMovements()
        
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
    
    private func getAvailableMovements() async -> [Movement] {
        // Try to fetch from adapter view first
        do {
            let response: [Movement] = try await supabase
                .from("movement_library")
                .select("*")
                .limit(100)
                .execute()
                .value
            if !response.isEmpty {
                return response
            }
        } catch {
            // Fallback to hardcoded list below
        }
        // Fallback: minimal static set
        return [
            Movement(id: 1, name: "Squat", description: "Basic squat movement", videoURL: nil, jointsImpacted: ["ankle", "knee", "hip"], musclesImpacted: ["quad", "glute"], superMetricsImpacted: ["functional_strength"], sportsImpacted: ["Soccer", "Basketball"], intensityOptions: ["reps", "weight"], recoveryImpactScore: 0.3, resilienceImpactScore: 0.7, resultsImpactScore: 0.8),
            Movement(id: 2, name: "Deadlift", description: "Hip hinge movement", videoURL: nil, jointsImpacted: ["hip", "knee"], musclesImpacted: ["hamstring", "glute"], superMetricsImpacted: ["functional_strength"], sportsImpacted: ["Football"], intensityOptions: ["reps", "weight"], recoveryImpactScore: 0.2, resilienceImpactScore: 0.8, resultsImpactScore: 0.9),
            Movement(id: 3, name: "Rest", description: "Active recovery", videoURL: nil, jointsImpacted: [], musclesImpacted: [], superMetricsImpacted: [], sportsImpacted: [], intensityOptions: [], recoveryImpactScore: 0.9, resilienceImpactScore: 0.1, resultsImpactScore: 0.1),
            Movement(id: 4, name: "Walk", description: "Low intensity cardio", videoURL: nil, jointsImpacted: ["ankle", "knee", "hip"], musclesImpacted: ["quad", "hamstring"], superMetricsImpacted: ["aerobic_capacity"], sportsImpacted: ["Running"], intensityOptions: ["distance", "time"], recoveryImpactScore: 0.7, resilienceImpactScore: 0.3, resultsImpactScore: 0.2)
        ]
    }
    
    func getCurrentPlan(profileId: String) async throws -> Plan? {
        let resp = try await supabase
            .from("plans")
            .select("id,profile_id,start_date,end_date,created_at")
            .eq("profile_id", value: profileId)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
        let arr = toArray(resp.data)
        print("[PlanService] plans raw: \(String(data: resp.data ?? Data(), encoding: .utf8) ?? "<nil>")")
        logArraySummary(label: "plans", data: arr)
        guard let r = arr.first else { return nil }

        var plan = Plan(
            id: string(r, "id") ?? "",
            profileId: string(r, "profile_id") ?? "",
            startDate: parseDateString(string(r, "start_date")),
            endDate: parseDateString(string(r, "end_date")),
            createdAt: parseDateString(string(r, "created_at")),
            phases: []
        )

        let phases = try await getPlanPhases(planId: plan.id)
        plan.phases = phases
        return plan
    }
    
    private func getPlanPhases(planId: String) async throws -> [PlanPhase] {
        let resp = try await supabase
            .from("plan_phases")
            .select("id,plan_id,phase_number,recovery_weight,resilience_weight,results_weight,start_date,end_date")
            .eq("plan_id", value: planId)
            .order("phase_number", ascending: true)
            .execute()
        let arr = toArray(resp.data)
        print("[PlanService] plan_phases raw: \(String(data: resp.data ?? Data(), encoding: .utf8) ?? "<nil>")")
        logArraySummary(label: "plan_phases", data: arr)
        var phases: [PlanPhase] = []
        for pr in arr {
            print("[PlanService] Mapping phase id=\(string(pr, "id") ?? "<nil>")")
            var phase = PlanPhase(
                id: string(pr, "id") ?? "",
                planId: string(pr, "plan_id") ?? "",
                phaseNumber: int(pr, "phase_number") ?? 0,
                recoveryWeight: double(pr, "recovery_weight") ?? 0,
                resilienceWeight: double(pr, "resilience_weight") ?? 0,
                resultsWeight: double(pr, "results_weight") ?? 0,
                startDate: parseDateString(string(pr, "start_date")),
                endDate: parseDateString(string(pr, "end_date")),
                dailyWorkouts: []
            )
            let workouts = try await getDailyWorkouts(phaseId: phase.id)
            phase.dailyWorkouts = workouts
            phases.append(phase)
        }
        return phases
    }
    
    private func getDailyWorkouts(phaseId: String) async throws -> [DailyWorkout] {
        let resp = try await supabase
            .from("daily_workouts")
            .select("id,plan_phase_id,workout_date,status")
            .eq("plan_phase_id", value: phaseId)
            .order("workout_date", ascending: true)
            .execute()
        let arr = toArray(resp.data)
        print("[PlanService] daily_workouts raw: \(String(data: resp.data ?? Data(), encoding: .utf8) ?? "<nil>")")
        logArraySummary(label: "daily_workouts", data: arr)
        var workouts: [DailyWorkout] = []
        for wr in arr {
            print("[PlanService] Mapping workout id=\(string(wr, "id") ?? "<nil>") date=\(string(wr, "workout_date") ?? "<nil>") status=\(string(wr, "status") ?? "<nil>")")
            var workout = DailyWorkout(
                id: string(wr, "id") ?? "",
                planPhaseId: string(wr, "plan_phase_id") ?? "",
                workoutDate: parseDateString(string(wr, "workout_date")),
                status: { let s = string(wr, "status")?.lowercased(); return s == "completed" ? .completed : (s == "in_progress" ? .inProgress : .pending) }(),
                movements: []
            )
            let movements = try await getWorkoutMovements(workoutId: workout.id)
            workout.movements = movements
            workouts.append(workout)
        }
        return workouts
    }
    
    private func getWorkoutMovements(workoutId: String) async throws -> [DailyWorkoutMovement] {
        let resp = try await supabase
            .from("daily_workout_movements")
            .select("id,daily_workout_id,movement_id,sequence,status,assigned_intensity,recovery_impact_score,resilience_impact_score,results_impact_score")
            .eq("daily_workout_id", value: workoutId)
            .order("sequence", ascending: true)
            .execute()
        let arr = toArray(resp.data)
        print("[PlanService] daily_workout_movements raw: \(String(data: resp.data ?? Data(), encoding: .utf8) ?? "<nil>")")
        logArraySummary(label: "daily_workout_movements", data: arr)
        
        return arr.map { r in
            print("[PlanService] Mapping movement id=\(string(r, "id") ?? "<nil>") movement_id=\(string(r, "movement_id") ?? String(int(r, "movement_id") ?? 0)) seq=\(int(r, "sequence") ?? -1) status=\(string(r, "status") ?? "<nil>")")
            DailyWorkoutMovement(
                id: string(r, "id") ?? "",
                dailyWorkoutId: string(r, "daily_workout_id") ?? "",
                movementId: int(r, "movement_id") ?? 0,
                sequence: int(r, "sequence") ?? 0,
                status: { let s = string(r, "status")?.lowercased(); return s == "completed" ? .completed : .pending }(),
                assignedIntensity: {
                    if let ai = r["assigned_intensity"] as? [String: Any] {
                        return Intensity(
                            reps: int(ai, "reps"),
                            sets: int(ai, "sets"),
                            weightKg: double(ai, "weight_kg"),
                            distanceMeters: double(ai, "distance_meters"),
                            durationSeconds: int(ai, "duration_seconds"),
                            rpe: int(ai, "rpe")
                        )
                    }
                    return nil
                }(),
                recoveryImpactScore: double(r, "recovery_impact_score") ?? 0,
                resilienceImpactScore: double(r, "resilience_impact_score") ?? 0,
                resultsImpactScore: double(r, "results_impact_score") ?? 0
            )
        }
    }

    // MARK: - Movement helpers
    /// Fetch a mapping of movement IDs to movement names for display in the UI
    func getMovementNamesByIds(_ ids: [Int]) async throws -> [Int: String] {
        let uniqueIds = Array(Set(ids))
        guard !uniqueIds.isEmpty else { return [:] }
        
        struct NameRow: Decodable { let id: Int; let name: String }
        let rows: [NameRow] = try await supabase
            .from("movement_library") // adapter view; falls back to minimal fields
            .select("id,name")
            .in("id", values: uniqueIds)
            .execute()
            .value
        
        return Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0.name) })
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
