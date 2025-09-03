import Foundation
import Supabase

@MainActor
class TrainingPlanService: ObservableObject {
    let supabase: SupabaseClient
    
    @Published var currentProgram: Program?
    @Published var currentUserProgram: UserProgram?
    @Published var currentWeek: ProgramWeek?
    @Published var currentWorkout: ProgramWorkout?
    @Published var todayWorkout: UserWorkout?
    @Published var isLoading = false
    @Published var error: Error?
    
    // New properties for complete program structure
    @Published var programPhases: [ProgramPhase] = []
    @Published var programWeeks: [ProgramWeek] = []
    @Published var programWorkouts: [ProgramWorkout] = []
    @Published var movementBlocks: [MovementBlock] = []
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    // MARK: - Complete Program Structure
    
    /// Fetch the complete program structure including phases, weeks, and workouts
    func fetchCompleteProgramStructure(programId: String) async throws -> (phases: [ProgramPhase], weeks: [ProgramWeek], workouts: [ProgramWorkout]) {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch phases
            let phases: [ProgramPhase] = try await supabase
                .from("program_phases")
                .select()
                .eq("program_id", value: programId)
                .order("phase_index")
                .execute()
                .value
            
            // Fetch weeks
            let weeks: [ProgramWeek] = try await supabase
                .from("program_weeks")
                .select()
                .eq("program_id", value: programId)
                .order("week_index")
                .execute()
                .value
            
            // Fetch all workouts
            let workouts: [ProgramWorkout] = try await supabase
                .from("program_workouts")
                .select()
                .eq("program_id", value: programId)
                .order("week_id")
                .order("day_index")
                .execute()
                .value
            
            await MainActor.run {
                self.programPhases = phases
                self.programWeeks = weeks
                self.programWorkouts = workouts
            }
            
            return (phases: phases, weeks: weeks, workouts: workouts)
        } catch {
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    /// Fetch movement blocks for a specific workout
    func fetchWorkoutMovementBlocks(workoutId: String) async throws -> [ProgramWorkoutBlock] {
        do {
            let response: [ProgramWorkoutBlock] = try await supabase
                .from("program_workout_blocks")
                .select("*, movement_blocks(*)")
                .eq("program_workout_id", value: workoutId)
                .order("sequence")
                .execute()
                .value
            
            return response
        } catch {
            throw error
        }
    }
    
    /// Fetch movement block items for a specific movement block
    func fetchMovementBlockItems(blockId: String) async throws -> [MovementBlockItem] {
        do {
            let response: [MovementBlockItem] = try await supabase
                .from("movement_block_items")
                .select("*, movements(*)")
                .eq("block_id", value: blockId)
                .order("sequence")
                .execute()
                .value
            
            return response
        } catch {
            throw error
        }
    }
    
    /// Get workouts for a specific week
    func getWorkoutsForWeek(weekId: String) -> [ProgramWorkout] {
        return programWorkouts.filter { $0.weekId == weekId }
    }
    
    /// Get weeks for a specific phase
    func getWeeksForPhase(phaseId: String) -> [ProgramWeek] {
        return programWeeks.filter { $0.phaseId == phaseId }
    }
    
    /// Get current week index based on program start date
    func getCurrentWeekIndex() -> Int? {
        guard let userProgram = currentUserProgram else { return nil }
        
        let startDate = userProgram.startDate
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        let weekIndex = (daysSinceStart / 7) + 1
        
        // Ensure week index is within program bounds
        if let program = currentProgram {
            return min(max(weekIndex, 1), program.weeks)
        }
        
        return weekIndex
    }
    
    /// Get current phase based on current week
    func getCurrentPhase() -> ProgramPhase? {
        guard let currentWeekIndex = getCurrentWeekIndex() else { return nil }
        
        // Find which phase contains the current week
        var cumulativeWeeks = 0
        for phase in programPhases {
            cumulativeWeeks += phase.weeksCount
            if currentWeekIndex <= cumulativeWeeks {
                return phase
            }
        }
        
        return programPhases.last
    }

    // MARK: - Program Management
    
    /// Fetch the active training program for a user
    func fetchActiveProgram() async throws -> Program? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: [Program] = try await supabase
                .from("programs")
                .select()
                .eq("is_active", value: true)
                .limit(1)
                .execute()
                .value
            
            if let program = response.first {
                await MainActor.run {
                    self.currentProgram = program
                }
                return program
            }
            return nil
        } catch {
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    /// Fetch program phases
    func fetchProgramPhases(programId: String) async throws -> [ProgramPhase] {
        do {
            let response: [ProgramPhase] = try await supabase
                .from("program_phases")
                .select()
                .eq("program_id", value: programId)
                .order("phase_index")
                .execute()
                .value
            
            return response
        } catch {
            throw error
        }
    }
    
    /// Fetch program weeks
    func fetchProgramWeeks(programId: String) async throws -> [ProgramWeek] {
        do {
            let response: [ProgramWeek] = try await supabase
                .from("program_weeks")
                .select()
                .eq("program_id", value: programId)
                .order("week_index")
                .execute()
                .value
            
            return response
        } catch {
            throw error
        }
    }
    
    /// Fetch workouts for a specific week
    func fetchWeekWorkouts(weekId: String) async throws -> [ProgramWorkout] {
        do {
            let response: [ProgramWorkout] = try await supabase
                .from("program_workouts")
                .select()
                .eq("week_id", value: weekId)
                .order("day_index")
                .execute()
                .value
            
            return response
        } catch {
            throw error
        }
    }
    
    /// Fetch a specific week by index
    func fetchWeek(weekIndex: Int) async throws -> ProgramWeek? {
        guard let program = currentProgram else { return nil }
        
        do {
            let response: [ProgramWeek] = try await supabase
                .from("program_weeks")
                .select()
                .eq("program_id", value: program.id)
                .eq("week_index", value: weekIndex)
                .limit(1)
                .execute()
                .value
            
            if let week = response.first {
                await MainActor.run {
                    self.currentWeek = week
                }
                return week
            }
            return nil
        } catch {
            throw error
        }
    }
    
    /// Fetch the active training program assignment for the current user
    func fetchActiveUserProgram() async throws -> UserProgram? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Get current user's ID
            let user = try await supabase.auth.session.user
            let userId = user.id.uuidString
            
            // Fetch most recent user_program regardless of status (planned/active)
            // Note: order by start_date desc, then created_at desc
            let response: [UserProgram] = try await supabase
                .from("user_programs")
                .select("*, program:programs(*)")
                .eq("user_id", value: userId)
                .order("start_date", ascending: false)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
            
            if var userProgram = response.first {
                // Ensure we have the Program model populated; if not, fetch it
                if userProgram.program == nil {
                    let programs: [Program] = try await supabase
                        .from("programs")
                        .select()
                        .eq("id", value: userProgram.programId)
                        .limit(1)
                        .execute()
                        .value
                    if let program = programs.first {
                        await MainActor.run {
                            self.currentProgram = program
                        }
                    }
                } else {
                    await MainActor.run {
                        self.currentProgram = userProgram.program
                    }
                }
                await MainActor.run {
                    self.currentUserProgram = userProgram
                }
                return userProgram
            }
            return nil
        } catch {
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    /// Fetch the user's workout for today
    func fetchTodayWorkout() async throws -> UserWorkout? {
        do {
            // Use resolved user_program to scope today's workout
            if currentUserProgram == nil {
                let _ = try await fetchActiveUserProgram()
            }
            guard let up = currentUserProgram else { return nil }
            
            let today = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let todayString = dateFormatter.string(from: today)
            
            let response: [UserWorkout] = try await supabase
                .from("user_workouts")
                .select()
                .eq("user_program_id", value: up.id)
                .eq("scheduled_date", value: todayString)
                .limit(1)
                .execute()
                .value
            
            if let workout = response.first {
                await MainActor.run {
                    self.todayWorkout = workout
                }
                return workout
            }
            return nil
        } catch {
            throw error
        }
    }
    
    /// Fetch user's workout history
    func fetchUserWorkoutHistory(limit: Int = 10) async throws -> [UserWorkout] {
        do {
            if currentUserProgram == nil {
                let _ = try await fetchActiveUserProgram()
            }
            guard let up = currentUserProgram else { return [] }
            
            let response: [UserWorkout] = try await supabase
                .from("user_workouts")
                .select()
                .eq("user_program_id", value: up.id)
                .order("scheduled_date", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            return response
        } catch {
            throw error
        }
    }
    

    
    // MARK: - User Progress Tracking
    
    /// Start a workout session
    func startWorkout(workoutId: String, userId: String) async throws -> String {
        do {
            let response: [String: String] = try await supabase
                .rpc("update_user_workout_status", params: [
                    "p_user_workout_id": workoutId,
                    "p_status": "in_progress"
                ])
                .execute()
                .value
            
            if let updatedWorkoutId = response["id"] {
                // Refresh today's workout
                let _ = try await fetchTodayWorkout()
                return updatedWorkoutId
            } else {
                throw NSError(domain: "TrainingPlanService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to start workout"])
            }
        } catch {
            throw error
        }
    }
    
    /// Complete a workout session
    func completeWorkout(workoutId: String, rpeSession: Double?, durationMinutes: Int?, notes: String?, userId: String) async throws -> String {
        do {
            let response: [String: String] = try await supabase
                .rpc("update_user_workout_status", params: [
                    "p_user_workout_id": workoutId,
                    "p_status": "completed",
                    "p_rpe_session": rpeSession?.description ?? "",
                    "p_duration_min": durationMinutes?.description ?? "",
                    "p_user_notes": notes ?? ""
                ])
                .execute()
                .value
            
            if let updatedWorkoutId = response["id"] {
                // Refresh today's workout
                let _ = try await fetchTodayWorkout()
                return updatedWorkoutId
            } else {
                throw NSError(domain: "TrainingPlanService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to complete workout"])
            }
        } catch {
            throw error
        }
    }
    

    
    // MARK: - Utility Methods
    
    /// Get current week based on program start date
    func getCurrentWeek(program: Program) -> Int {
        let startDate = program.createdAt
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return min((daysSinceStart / 7) + 1, program.weeks)
    }
    
    /// Check if user has completed a workout
    func hasCompletedWorkout(workoutId: String, userId: String) async throws -> Bool {
        do {
            let response: [UserWorkout] = try await supabase
                .from("user_workouts")
                .select("id")
                .eq("workout_id", value: workoutId)
                .eq("user_id", value: userId)
                .eq("status", value: "completed")
                .execute()
                .value
            
            return !response.isEmpty
        } catch {
            throw error
        }
    }
    
        /// Assign a program to the current user
    func assignProgram(programSlug: String, startDate: Date, userId: String) async throws -> String {
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let startDateString = dateFormatter.string(from: startDate)
            
            let response: [String: String] = try await supabase
                .rpc("assign_program", params: [
                    "p_user_id": userId,
                    "p_program_slug": programSlug,
                    "p_start_date": startDateString,
                    "p_day_offsets": "[0,2,4]" // Mon, Wed, Fri as JSON string
                ])
                .execute()
                .value
            
            if let userProgramId = response["id"] {
                // Refresh the current user program
                let _ = try await fetchActiveUserProgram()
                return userProgramId
            } else {
                throw NSError(domain: "TrainingPlanService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get user program ID"])
            }
        } catch {
            throw error
        }
    }
}
