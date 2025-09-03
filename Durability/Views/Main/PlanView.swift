import SwiftUI
import Supabase

struct PlanView: View {
    @StateObject private var trainingPlanService: TrainingPlanService
    @State private var showingProgramAssignment = false
    
    init(supabase: SupabaseClient) {
        self._trainingPlanService = StateObject(wrappedValue: TrainingPlanService(supabase: supabase))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Training Plan")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let _ = trainingPlanService.currentUserProgram, let program = trainingPlanService.currentProgram {
                        Text(program.name)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No active program")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Current Program Progress Card
                if let _ = trainingPlanService.currentUserProgram,
                   let currentProgram = trainingPlanService.currentProgram,
                   let currentPhase = trainingPlanService.getCurrentPhase(),
                   let currentWeekIndex = trainingPlanService.getCurrentWeekIndex() {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Current Progress")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        CurrentProgressCard(
                            currentPhase: currentPhase,
                            currentWeek: currentWeekIndex,
                            totalWeeks: currentProgram.weeks
                        )
                        .padding(.horizontal)
                    }
                }
                
                // Section 1: High-level overview of 3 phases
                if trainingPlanService.currentUserProgram != nil && !trainingPlanService.programPhases.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Program Phases")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 16) {
                            ForEach(trainingPlanService.programPhases, id: \.id) { phase in
                                PhaseOverviewCard(phase: phase)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Section 2: Week ahead and remaining workouts
                if trainingPlanService.currentUserProgram != nil {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("This Week")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        if let currentWeekIndex = trainingPlanService.getCurrentWeekIndex(),
                           let currentWeek = trainingPlanService.programWeeks.first(where: { $0.weekIndex == currentWeekIndex }) {
                            WeekAheadCard(
                                week: currentWeek,
                                trainingPlanService: trainingPlanService
                            )
                            .padding(.horizontal)
                        } else {
                            Text("No workouts scheduled this week")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                }
                
                // Section 3: Modify Plan Button
                VStack(alignment: .leading, spacing: 16) {
                    Text("Plan Management")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    Button(action: {
                        // Modify plan functionality - for now does nothing
                    }) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text("Modify Plan")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // Today's Workout Section (if exists)
                if let todayWorkout = trainingPlanService.todayWorkout {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Workout")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        TodayWorkoutCard(workout: todayWorkout, formatDate: formatDate)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            loadTrainingPlan()
        }
    }
    
    private func loadTrainingPlan() {
        Task {
            do {
                // First resolve the user's assigned program (most recent)
                let _ = try await trainingPlanService.fetchActiveUserProgram()
                
                // If we have a program, fetch today's workout and complete structure
                if trainingPlanService.currentUserProgram != nil, let program = trainingPlanService.currentProgram {
                    let _ = try await trainingPlanService.fetchTodayWorkout()
                    let _ = try await trainingPlanService.fetchCompleteProgramStructure(programId: program.id)
                }
            } catch {
                print("Error loading training plan: \(error)")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct PhaseOverviewCard: View {
    let phase: ProgramPhase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Phase \(phase.phaseIndex)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(phase.weeksCount) weeks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Phase indicator
                Circle()
                    .fill(phaseColor)
                    .frame(width: 12, height: 12)
            }
            
            // Use default description since ProgramPhase doesn't have a description property
            Text("Phase \(phase.phaseIndex) focuses on building foundational strength and movement patterns.")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var phaseColor: Color {
        switch phase.phaseIndex {
        case 1: return .blue
        case 2: return .green
        case 3: return .orange
        default: return .gray
        }
    }
}

struct WeekAheadCard: View {
    let week: ProgramWeek
    @ObservedObject var trainingPlanService: TrainingPlanService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Week \(week.weekIndex)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(remainingWorkouts.count) workouts remaining")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Progress indicator
                ProgressView(value: Double(completedWorkouts.count), total: Double(weekWorkouts.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                    .frame(width: 60)
            }
            
            if remainingWorkouts.isEmpty {
                Text("All workouts completed this week! 🎉")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(remainingWorkouts) { workout in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Day \(workout.dayIndex)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(workout.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var weekWorkouts: [ProgramWorkout] {
        return trainingPlanService.getWorkoutsForWeek(weekId: week.id)
    }
    
    private var completedWorkouts: [ProgramWorkout] {
        return weekWorkouts.filter { workout in
            // This would need to be implemented based on your workout completion logic
            // For now, returning empty array as placeholder
            return false
        }
    }
    
    private var remainingWorkouts: [ProgramWorkout] {
        return weekWorkouts.filter { workout in
            // This would need to be implemented based on your workout completion logic
            // For now, returning all workouts as remaining
            return true
        }
    }
}

struct CurrentProgressCard: View {
    let currentPhase: ProgramPhase
    let currentWeek: Int
    let totalWeeks: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Phase \(currentPhase.phaseIndex)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Week \(currentWeek) of \(totalWeeks)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Progress indicator
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(progressPercentage * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                    
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            ProgressView(value: progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var progressPercentage: Double {
        guard totalWeeks > 0 else { return 0.0 }
        return Double(currentWeek) / Double(totalWeeks)
    }
}

// Remove duplicate structs that are now in TrainingPlanOverviewView
// TodayWorkoutCard and StatusBadge are defined in TrainingPlanOverviewView

#Preview {
    PlanView(supabase: SupabaseClient(
        supabaseURL: URL(string: "https://example.com")!,
        supabaseKey: "key"
    ))
}
