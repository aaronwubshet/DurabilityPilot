import SwiftUI
import Supabase

struct TrainingPlanTestView: View {
    @StateObject private var trainingPlanService: TrainingPlanService
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(supabase: SupabaseClient) {
        self._trainingPlanService = StateObject(wrappedValue: TrainingPlanService(supabase: supabase))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Training Plan Test")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if trainingPlanService.isLoading {
                    ProgressView("Loading...")
                        .scaleEffect(1.5)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Active Program Section
                            if let program = trainingPlanService.currentProgram {
                                ProgramInfoView(program: program)
                            }
                            
                            // Current Week Section
                            if let week = trainingPlanService.currentWeek {
                                WeekInfoView(week: week)
                            }
                            
                            // Current Workout Section
                            if let workout = trainingPlanService.currentWorkout {
                                WorkoutInfoView(workout: workout)
                            }
                            
                            // Test Buttons
                            TestButtonsView(trainingPlanService: trainingPlanService)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Training Plan Test")
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadTrainingPlan()
            }
        }
    }
    
    private func loadTrainingPlan() {
        Task {
            do {
                try await trainingPlanService.fetchActiveProgram()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Subviews

struct ProgramInfoView: View {
    let program: Program
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Program")
                .font(.headline)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Name: \(program.name)")
                Text("Duration: \(program.weeks) weeks")
                Text("Workouts per week: \(program.workoutsPerWeek)")
                Text("Version: \(program.version)")
                Text("Active: \(program.isActive ? "Yes" : "No")")
            }
            .font(.subheadline)
            
            Divider()
        }
    }
}

struct WeekInfoView: View {
    let week: ProgramWeek
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Week")
                .font(.headline)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Week: \(week.weekIndex)")
                Text("Phase Week: \(week.phaseWeekIndex)")
                Text("Phase ID: \(week.phaseId)")
            }
            .font(.subheadline)
            
            Divider()
        }
    }
}

struct WorkoutInfoView: View {
    let workout: ProgramWorkout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Workout")
                .font(.headline)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Day: \(workout.dayIndex)")
                Text("Title: \(workout.title ?? "No Title")")
                Text("Week ID: \(workout.weekId)")
            }
            .font(.subheadline)
            
            Divider()
        }
    }
}

struct TestButtonsView: View {
    @ObservedObject var trainingPlanService: TrainingPlanService
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Test Actions")
                .font(.headline)
                .foregroundColor(.purple)
            
            Button("Fetch Active Program") {
                Task {
                    do {
                        try await trainingPlanService.fetchActiveProgram()
                    } catch {
                        print("Error fetching program: \(error)")
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            
            if let program = trainingPlanService.currentProgram {
                Button("Fetch Week 1") {
                    Task {
                        do {
                            try await trainingPlanService.fetchWeek(weekIndex: 1)
                        } catch {
                            print("Error fetching week: \(error)")
                        }
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Fetch Today's Workout") {
                    Task {
                        do {
                            try await trainingPlanService.fetchTodayWorkout()
                        } catch {
                            print("Error fetching workout: \(error)")
                        }
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview {
    // This would need a real Supabase client in production
    Text("Training Plan Test View")
}
