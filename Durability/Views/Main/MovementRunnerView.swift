import SwiftUI

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
    
    private func dismiss() { 
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) 
    }
    
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

#Preview {
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
            )
        ]
    )
    
    return MovementRunnerView(
        workout: mockWorkout,
        startIndex: 0,
        onFinishMovement: { _ in }
    )
    .environmentObject(AppState())
}
