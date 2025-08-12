import SwiftUI

struct TodayWorkoutView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentWorkout: DailyWorkout?
    @State private var isLoading = false
    @State private var showRunner = false
    @State private var showAssessmentPrompt = false
    @State private var insights: [String] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Loading today's workout...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let workout = currentWorkout {
                        TodayWorkoutContent(workout: workout)
                    } else {
                        NoWorkoutView()
                    }
                }
                .padding()
            }
            .navigationTitle("Today's Workout")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .onAppear {
                loadTodayWorkout()
                Task { await checkPrompts() }
            }
        }
    }
    
    private func loadTodayWorkout() {
        isLoading = true
        
        Task {
            // TODO: Load today's workout from the plan
            // For now, create a mock workout
            let mockWorkout = DailyWorkout(
                id: UUID().uuidString,
                planPhaseId: UUID().uuidString,
                workoutDate: Date(),
                status: .pending,
                movements: [
                    DailyWorkoutMovement(
                        id: UUID().uuidString,
                        dailyWorkoutId: UUID().uuidString,
                        movementId: 1,
                        sequence: 1,
                        status: .pending,
                        assignedIntensity: Intensity(reps: 10, sets: 3),
                        recoveryImpactScore: 0.3,
                        resilienceImpactScore: 0.7,
                        resultsImpactScore: 0.8
                    ),
                    DailyWorkoutMovement(
                        id: UUID().uuidString,
                        dailyWorkoutId: UUID().uuidString,
                        movementId: 2,
                        sequence: 2,
                        status: .pending,
                        assignedIntensity: Intensity(reps: 8, sets: 3),
                        recoveryImpactScore: 0.2,
                        resilienceImpactScore: 0.8,
                        resultsImpactScore: 0.9
                    )
                ]
            )
            
            await MainActor.run {
                currentWorkout = mockWorkout
                isLoading = false
                insights = generateInsights(for: mockWorkout)
            }
        }
    }

    private func checkPrompts() async {
        guard let profileId = appState.currentUser?.id else { return }
        // Prompt to retake assessment after 7 completed days in last 7 days
        if let count = try? await appState.planService.countCompletedWorkouts(profileId: profileId, since: Calendar.current.date(byAdding: .day, value: -7, to: Date())!), count >= 7 {
            await MainActor.run { showAssessmentPrompt = true }
        }
    }
    
    private func generateInsights(for workout: DailyWorkout) -> [String] {
        // Very simple heuristics for demo purposes
        let hasStrength = workout.movements.contains { $0.resultsImpactScore > 0.6 }
        let hasRecovery = workout.movements.contains { $0.recoveryImpactScore > 0.6 }
        var tips: [String] = []
        if hasStrength { tips.append("Brace your core; imagine pulling the floor apart with your feet.") }
        if hasRecovery { tips.append("Move deliberately; breathe in through the nose, out through the mouth.") }
        tips.append("Watch for asymmetry: keep hips level and knees tracking over toes.")
        return tips
    }
}

struct TodayWorkoutContent: View {
    let workout: DailyWorkout
    @State private var currentMovementIndex = 0
    @State private var isRunnerPresented = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Workout status
            HStack {
                Text("Workout Status:")
                    .font(.headline)
                
                Spacer()
                
                Text(workout.status.rawValue.capitalized)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
            }
            
            // Current movement
            if currentMovementIndex < workout.movements.count {
                let movement = workout.movements[currentMovementIndex]
                MovementCard(movement: movement, isActive: true)
                
                Button {
                    isRunnerPresented = true
                } label: {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Start Workout")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .padding(.top, 4)
            }
            
            // Movement list
            VStack(alignment: .leading, spacing: 10) {
                Text("Today's Movements")
                    .font(.headline)
                
                ForEach(Array(workout.movements.enumerated()), id: \.element.id) { index, movement in
                    MovementCard(
                        movement: movement,
                        isActive: index == currentMovementIndex
                    )
                }
            }
            
            Spacer()
        }
        .sheet(isPresented: $isRunnerPresented) {
            MovementRunnerView(
                workout: workout,
                startIndex: currentMovementIndex,
                onFinishMovement: { nextIndex in
                    currentMovementIndex = nextIndex
                }
            )
        }
    }
    
    private var statusColor: Color {
        switch workout.status {
        case .pending: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        }
    }
}

struct MovementCard: View {
    let movement: DailyWorkoutMovement
    let isActive: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Movement \(movement.sequence)")
                    .font(.headline)
                
                Text("Squat") // TODO: Get movement name from ID
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let intensity = movement.assignedIntensity, let reps = intensity.reps, let sets = intensity.sets {
                    Text("\(reps) reps × \(sets) sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: isActive ? "play.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isActive ? .accentColor : .secondary)
        }
        .padding()
        .background(isActive ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

struct NoWorkoutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No workout scheduled for today")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your personalized plan will be generated after completing the assessment.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    TodayWorkoutView()
        .environmentObject(AppState())
}
