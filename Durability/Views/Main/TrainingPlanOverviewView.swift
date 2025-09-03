import SwiftUI

struct TrainingPlanOverviewView: View {
    @ObservedObject var trainingPlanService: TrainingPlanService
    @State private var selectedPhaseIndex = 0
    @State private var expandedWeeks: Set<String> = []
    @State private var showingWorkoutDetail = false
    @State private var selectedWorkout: ProgramWorkout?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Training Plan Details")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let program = trainingPlanService.currentProgram {
                        Text(program.name)
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("\(program.weeks) weeks • \(program.workoutsPerWeek) workouts per week")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("4 blocks per workout • 2 movements per block")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Structure Section
                if trainingPlanService.currentUserProgram != nil && !trainingPlanService.programPhases.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Structure")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        // Phase Selector - 3 phases side by side
                        HStack(spacing: 12) {
                            ForEach(Array(trainingPlanService.programPhases.enumerated()), id: \.element.id) { index, phase in
                                PhaseCard(
                                    phase: phase,
                                    isSelected: selectedPhaseIndex == index,
                                    isCurrent: trainingPlanService.getCurrentPhase()?.id == phase.id,
                                    onTap: {
                                        selectedPhaseIndex = index
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Week Cards for Selected Phase
                        if let selectedPhase = trainingPlanService.programPhases[safe: selectedPhaseIndex] {
                            let phaseWeeks = trainingPlanService.programWeeks.filter { $0.phaseId == selectedPhase.id }
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Phase \(selectedPhase.phaseIndex) - \(selectedPhase.weeksCount) weeks")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                LazyVStack(spacing: 12) {
                                    ForEach(phaseWeeks) { week in
                                        WeekCard(
                                            week: week,
                                            isExpanded: expandedWeeks.contains(week.id),
                                            onToggle: {
                                                if expandedWeeks.contains(week.id) {
                                                    expandedWeeks.remove(week.id)
                                                } else {
                                                    expandedWeeks.insert(week.id)
                                                }
                                            },
                                            trainingPlanService: trainingPlanService
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Training Plan Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Set initial phase selection to current phase
            if let currentPhase = trainingPlanService.getCurrentPhase(),
               let phaseIndex = trainingPlanService.programPhases.firstIndex(where: { $0.id == currentPhase.id }) {
                selectedPhaseIndex = phaseIndex
            }
            
            // Load training plan data if not already loaded
            loadTrainingPlan()
        }
        .sheet(isPresented: $showingWorkoutDetail) {
            if let workout = selectedWorkout {
                WorkoutDetailView(workout: workout, trainingPlanService: trainingPlanService)
            }
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
}

// MARK: - Supporting Views

struct PhaseCard: View {
    let phase: ProgramPhase
    let isSelected: Bool
    let isCurrent: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text("Phase")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(phase.phaseIndex)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(phase.weeksCount) weeks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCurrent ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .accentColor
        } else if isCurrent {
            return Color.accentColor.opacity(0.1)
        } else {
            return Color(.systemGray5)
        }
    }
    
    private var foregroundColor: Color {
        if isSelected {
            return .white
        } else if isCurrent {
            return .accentColor
        } else {
            return .primary
        }
    }
}

struct WeekCard: View {
    let week: ProgramWeek
    let isExpanded: Bool
    let onToggle: () -> Void
    @ObservedObject var trainingPlanService: TrainingPlanService
    
    var body: some View {
        VStack(spacing: 0) {
            // Week Header
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Week \(week.weekIndex)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Phase \(week.phaseWeekIndex ?? 0)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 1)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Week Content
            if isExpanded {
                WeekExpandedContent(week: week, trainingPlanService: trainingPlanService)
                    .padding(.top, 8)
            }
        }
    }
}

struct WeekExpandedContent: View {
    let week: ProgramWeek
    let trainingPlanService: TrainingPlanService
    @State private var weekWorkouts: [ProgramWorkout] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isLoading {
                ProgressView("Loading workouts...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if weekWorkouts.isEmpty {
                Text("No workouts scheduled for this week")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                                                    LazyVStack(spacing: 8) {
                                        ForEach(weekWorkouts) { workout in
                                            WorkoutDayCard(workout: workout, trainingPlanService: trainingPlanService)
                                        }
                                    }
            }
        }
        .onAppear {
            loadWeekWorkouts()
        }
    }
    
    private func loadWeekWorkouts() {
        Task {
            let workouts = trainingPlanService.getWorkoutsForWeek(weekId: week.id)
            await MainActor.run {
                self.weekWorkouts = workouts
                self.isLoading = false
            }
        }
    }
}

struct WorkoutDayCard: View {
    let workout: ProgramWorkout
    let trainingPlanService: TrainingPlanService
    @State private var showingWorkoutDetail = false
    
    var body: some View {
        Button(action: {
            showingWorkoutDetail = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
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
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingWorkoutDetail) {
            WorkoutDetailView(workout: workout, trainingPlanService: trainingPlanService)
        }
    }
}

struct WorkoutDetailView: View {
    let workout: ProgramWorkout
    @ObservedObject var trainingPlanService: TrainingPlanService
    @Environment(\.dismiss) private var dismiss
    @State private var movementBlocks: [ProgramWorkoutBlock] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Workout Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(workout.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Day \(workout.dayIndex)")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Movement Blocks
                    if isLoading {
                        ProgressView("Loading workout details...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if movementBlocks.isEmpty {
                        Text("No movement blocks found for this workout")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Movement Blocks")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 16) {
                                ForEach(movementBlocks) { block in
                                    MovementBlockCard(block: block, trainingPlanService: trainingPlanService)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadWorkoutDetails()
            }
        }
    }
    
    private func loadWorkoutDetails() {
        Task {
            do {
                let blocks = try await trainingPlanService.fetchWorkoutMovementBlocks(workoutId: workout.id)
                await MainActor.run {
                    self.movementBlocks = blocks
                    self.isLoading = false
                }
            } catch {
                print("Error loading workout details: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

struct MovementBlockCard: View {
    let block: ProgramWorkoutBlock
    let trainingPlanService: TrainingPlanService
    @State private var blockItems: [MovementBlockItem] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Block Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Block \(block.sequence)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(block.movementBlock?.name ?? "Unknown Block")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if let equipment = block.movementBlock?.requiredEquipment, !equipment.isEmpty {
                    Label("Equipment Required", systemImage: "dumbbell")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Movement Items - 2 movements as half-width cards
            if isLoading {
                ProgressView("Loading movements...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if blockItems.isEmpty {
                Text("No movements found for this block")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                HStack(spacing: 12) {
                    ForEach(blockItems) { item in
                        MovementItemCard(movementItem: item)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            loadBlockItems()
        }
    }
    
    private func loadBlockItems() {
        Task {
            do {
                let items = try await trainingPlanService.fetchMovementBlockItems(blockId: block.movementBlockId)
                await MainActor.run {
                    self.blockItems = items
                    self.isLoading = false
                }
            } catch {
                print("Error loading movement block items: \(error)")
                await MainActor.run {
                    self.isLoading = false
                    self.blockItems = []
                }
            }
        }
    }
}

struct MovementItemCard: View {
    let movementItem: MovementBlockItem
    @State private var showingMovementDetail = false
    
    var body: some View {
        Button(action: {
            showingMovementDetail = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                if let movement = movementItem.movement {
                    Text(movement.name ?? "Unknown Movement")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text("Sequence \(movementItem.sequence)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Movement \(movementItem.sequence)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(radius: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingMovementDetail) {
            if let movement = movementItem.movement {
                // Convert MovementMinimal to Movement for the detail view
                let fullMovement = Movement(
                    id: Int(movement.id) ?? 0,
                    name: movement.name ?? "Unknown Movement",
                    description: movement.description ?? "",
                    videoURL: nil,
                    jointsImpacted: [],
                    musclesImpacted: [],
                    superMetricsImpacted: [],
                    sportsImpacted: [],
                    intensityOptions: [],
                    recoveryImpactScore: 0.0,
                    resilienceImpactScore: 0.0,
                    resultsImpactScore: 0.0
                )
                MovementDetailView(movement: fullMovement)
            }
        }
    }
}

// MARK: - Extensions

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    TrainingPlanOverviewView(trainingPlanService: TrainingPlanService(supabase: SupabaseManager.shared.client))
}
