import SwiftUI

struct TodayWorkoutView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showingProfile: Bool
    @State private var currentWorkout: DailyWorkout?
    @State private var isLoading = false
    @State private var showRunner = false
    @State private var showAssessmentPrompt = false
    @State private var insights: [String] = []
    @State private var showMovementLibrary = false
    @State private var movementNameById: [Int: String] = [:]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomLeading) {
                Color.darkSpaceGrey
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        if isLoading {
                            ProgressView("Loading today's workout...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if let workout = currentWorkout {
                            TodayWorkoutContent(workout: workout, movementNameById: movementNameById)
                        } else {
                            NoWorkoutView()
                        }
                    }
                    .padding()
                }
                
                // Floating Button
                Button(action: {
                    showMovementLibrary = true
                }) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .resizable()
                        .frame(width: 48, height: 48)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.leading, 24)
                .padding(.bottom, 80) // Adjust as needed to sit above the tab bar
                .accessibilityLabel("Open Movement Library")
            }
            .navigationTitle("Today's Workout")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingProfile = true
                    }) {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .onAppear {
                loadTodayWorkout()
                Task { await checkPrompts() }
            }
        }
        .sheet(isPresented: $showMovementLibrary) {
            MovementLibraryView()
        }
    }
    
    private func loadTodayWorkout() {
        print("[TodayWorkoutView] loadTodayWorkout() called")
        isLoading = true
        
        Task {
            guard let profileId = appState.currentUser?.id else {
                print("[TodayWorkoutView] No profileId found on appState.currentUser")
                await MainActor.run { isLoading = false }
                return
            }
            print("[TodayWorkoutView] Using profileId: \(profileId)")
            
            do {
                // Get current plan and pick the first available workout (no date filtering)
                if let plan = try await appState.planService.getCurrentPlan(profileId: profileId) {
                    print("[TodayWorkoutView] Loaded plan id=\(plan.id), phases=\(plan.phases.count)")
                    let allWorkouts = plan.phases.flatMap { phase in
                        print("[TodayWorkoutView] Phase id=\(phase.id) has \(phase.dailyWorkouts.count) workouts")
                        return phase.dailyWorkouts
                    }
                    print("[TodayWorkoutView] Total workouts across phases: \(allWorkouts.count)")
                    if let anyWorkout = allWorkouts.first {
                        print("[TodayWorkoutView] Selected workout id=\(anyWorkout.id) date=\(anyWorkout.workoutDate) movements=\(anyWorkout.movements.count)")
                        let ids = anyWorkout.movements.map { $0.movementId }
                        print("[TodayWorkoutView] Movement IDs: \(ids)")
                        let nameMap = (try? await appState.planService.getMovementNamesByIds(ids)) ?? [:]
                        print("[TodayWorkoutView] Resolved movement names: \(nameMap.count)")
                        await MainActor.run {
                            currentWorkout = anyWorkout
                            movementNameById = nameMap
                            isLoading = false
                            insights = generateInsights(for: anyWorkout)
                        }
                        return
                    } else {
                        print("[TodayWorkoutView] No workouts found in plan.phases")
                    }
                } else {
                    print("[TodayWorkoutView] No current plan found for profileId: \(profileId)")
                }
                
                // No workout found
                await MainActor.run {
                    currentWorkout = nil
                    isLoading = false
                    insights = []
                }
                print("[TodayWorkoutView] Set state to no workout available")
            } catch {
                print("[TodayWorkoutView] Error loading workout: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                    // Keep current workout if loading fails
                }
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
    let movementNameById: [Int: String]
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
                MovementCard(movement: movement, isActive: true, name: movementNameById[movement.movementId])
                
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
                        isActive: index == currentMovementIndex,
                        name: movementNameById[movement.movementId]
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
    let name: String?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Movement \(movement.sequence)")
                    .font(.headline)
                
                Text(name ?? "Movement \(movement.movementId)")
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
    TodayWorkoutView(showingProfile: .constant(false))
        .environmentObject(AppState())
}
