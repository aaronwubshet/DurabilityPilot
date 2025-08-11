import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Int = 1 // 0 = Plan, 1 = Today, 2 = Progress
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PlanView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Plan")
                }
                .tag(0)
            
            TodayWorkoutView()
                .tabItem {
                    Image(systemName: "figure.walk")
                    Text("Today")
                }
                .tag(1)
            
            ProgressDashboardView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(2)
        }
    }
}

struct TodayWorkoutView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentWorkout: DailyWorkout?
    @State private var isLoading = false
    @State private var showRunner = false
    @State private var showAssessmentPrompt = false
    @State private var showProfilePrompt = false
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
        // Prompt to retake profile intake in last week of plan
        if let plan = try? await appState.planService.getCurrentPlan(profileId: profileId) {
            let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: plan.endDate).day ?? 999
            if daysLeft <= 7 {
                await MainActor.run { showProfilePrompt = true }
            }
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

// MARK: - Runner

struct MovementRunnerView: View {
    @EnvironmentObject var appState: AppState
    let workout: DailyWorkout
    @State private var index: Int
    @State private var isPaused = false
    @State private var secondsRemaining: Int = 60
    var onFinishMovement: (Int) -> Void
    
    init(workout: DailyWorkout, startIndex: Int, onFinishMovement: @escaping (Int) -> Void) {
        self.workout = workout
        self._index = State(initialValue: startIndex)
        self.onFinishMovement = onFinishMovement
    }
    
    var body: some View {
        NavigationStack {
            let movement = workout.movements[index]
            VStack(alignment: .leading, spacing: 16) {
                Text("Movement \(movement.sequence)")
                    .font(.headline)
                Text(movementName(movement))
                    .font(.title3)
                    .fontWeight(.semibold)
                
                // Description placeholder
                Text("Keep neutral spine. Engage core. Controlled tempo.")
                    .foregroundColor(.secondary)
                
                // Timer
                HStack(spacing: 16) {
                    Text("Timer")
                        .font(.headline)
                    Spacer()
                    Text(timeString)
                        .monospacedDigit()
                        .font(.system(size: 28, weight: .bold))
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                HStack {
                    Button(isPaused ? "Resume" : "Pause & Save") {
                        isPaused.toggle()
                        if isPaused {
                            Task { await saveProgressPartial() }
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Finish Movement") {
                        Task { await finishMovementAndAdvance() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Workout")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                guard !isPaused else { return }
                if secondsRemaining > 0 { secondsRemaining -= 1 }
            }
        }
    }
    
    private func dismiss() { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
    
    private var timeString: String {
        let m = secondsRemaining / 60
        let s = secondsRemaining % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    private func movementName(_ m: DailyWorkoutMovement) -> String {
        switch m.movementId {
        case 1: return "Squat"
        case 2: return "Deadlift"
        case 3: return "Rest"
        case 4: return "Walk"
        default: return "Movement"
        }
    }
    
    private func saveProgressPartial() async {
        // Could persist elapsed time; for now, just mark workout in progress
        try? await appState.planService.updateWorkoutStatus(workoutId: workout.id, status: .inProgress)
    }
    
    private func finishMovementAndAdvance() async {
        let current = workout.movements[index]
        try? await appState.planService.updateMovementStatus(movementId: current.id, status: .completed)
        let nextIndex = index + 1
        if nextIndex >= workout.movements.count {
            try? await appState.planService.updateWorkoutStatus(workoutId: workout.id, status: .completed)
            dismiss()
        } else {
            index = nextIndex
            onFinishMovement(nextIndex)
            secondsRemaining = 60
        }
    }
}

struct ProgressTrackerView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Progress Tracking")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Coming soon...")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Progress")
        }
    }
}

struct PlanView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Training Plan")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Coming soon...")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Plan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.circle")
                    }
                }
            }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            List {
                Section("Integrations") {
                    NavigationLink("Apple Health") { HealthKitView(viewModel: OnboardingViewModel()) }
                }
                
                Section("Profile") {
                    NavigationLink("Edit Basic Info") { BasicInfoView(viewModel: OnboardingViewModel()) }
                    NavigationLink("Equipment") { EquipmentView(viewModel: OnboardingViewModel()) }
                    NavigationLink("Sports") { SportsView(viewModel: OnboardingViewModel()) }
                    NavigationLink("Injuries") { InjuryHistoryView(viewModel: OnboardingViewModel()) }
                    NavigationLink("Goals") { GoalsView(viewModel: OnboardingViewModel()) }
                }
                
                Section("Assessments") {
                    NavigationLink("Retake Movement Assessment") { AssessmentFlowView() }
                    NavigationLink("Retake Profile Intake") { OnboardingFlowView() }
                }
                
                Section("Account") {
                    Button(role: .destructive) {
                        Task { await appState.signOut() }
                    } label: {
                        Text("Sign Out")
                    }
                }
                
                Section("Legal") {
                    NavigationLink("Terms and Conditions") { LegalTextView(title: "Terms and Conditions") }
                    NavigationLink("Privacy Policy") { LegalTextView(title: "Privacy Policy") }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct LegalTextView: View {
    let title: String
    var body: some View {
        ScrollView {
            Text("Coming soon...")
                .foregroundColor(.secondary)
                .padding()
        }
        .navigationTitle(title)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
