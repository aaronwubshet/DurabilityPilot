import Foundation
import Supabase

@MainActor
class TrainingPlanService: ObservableObject {
    private let supabase: SupabaseClient
    
    @Published var currentProgram: Program?
    @Published var currentWeek: ProgramWeek?
    @Published var currentWorkout: ProgramWorkout?
    @Published var isLoading = false
    @Published var error: Error?
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
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
    
    /// Fetch today's workout based on current week
    func fetchTodayWorkout() async throws -> ProgramWorkout? {
        guard let week = currentWeek else { return nil }
        
        // For now, just fetch the first workout of the week
        // In a real app, you'd calculate the actual day
        do {
            let response: [ProgramWorkout] = try await supabase
                .from("program_workouts")
                .select()
                .eq("week_id", value: week.id)
                .order("day_index")
                .limit(1)
                .execute()
                .value
            
            if let workout = response.first {
                await MainActor.run {
                    self.currentWorkout = workout
                }
                return workout
            }
            return nil
        } catch {
            throw error
        }
    }
    
    /// Fetch workout blocks for a specific workout
    func fetchWorkoutBlocks(workoutId: String) async throws -> [ProgramWorkoutBlock] {
        do {
            let response: [ProgramWorkoutBlock] = try await supabase
                .from("program_workout_blocks")
                .select()
                .eq("program_workout_id", value: workoutId)
                .order("sequence")
                .execute()
                .value
            
            return response
        } catch {
            throw error
        }
    }
    
    /// Fetch movement blocks
    func fetchMovementBlocks() async throws -> [MovementBlock] {
        do {
            let response: [MovementBlock] = try await supabase
                .from("movement_blocks")
                .select()
                .execute()
                .value
            
            return response
        } catch {
            throw error
        }
    }
    
    /// Fetch movements for a specific block
    func fetchBlockMovements(blockId: String) async throws -> [MovementBlockItem] {
        do {
            let response: [MovementBlockItem] = try await supabase
                .from("movement_block_items")
                .select()
                .eq("block_id", value: blockId)
                .order("sequence")
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
            let workoutSession = UserWorkout(
                id: UUID().uuidString,
                userId: userId,
                workoutId: workoutId,
                startedAt: Date(),
                completedAt: nil,
                status: "in_progress"
            )
            
            let _ = try await supabase
                .from("user_workouts")
                .insert(workoutSession)
                .execute()
            
            return workoutSession.id
        } catch {
            throw error
        }
    }
    
    /// Complete a workout session
    func completeWorkout(sessionId: String) async throws {
        do {
            let _ = try await supabase
                .from("user_workouts")
                .update([
                    "completed_at": ISO8601DateFormatter().string(from: Date()),
                    "status": "completed"
                ])
                .eq("id", value: sessionId)
                .execute()
        } catch {
            throw error
        }
    }
    
    /// Log a set for a movement
    func logSet(sessionId: String, blockItemId: String, reps: Int, weight: Double?, notes: String?) async throws {
        do {
            let setLog = UserSetLog(
                id: UUID().uuidString,
                workoutSessionId: sessionId,
                blockItemId: blockItemId,
                reps: reps,
                weight: weight,
                notes: notes,
                createdAt: Date()
            )
            
            let _ = try await supabase
                .from("user_set_logs")
                .insert(setLog)
                .execute()
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
}
