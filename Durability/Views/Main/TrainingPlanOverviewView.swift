import SwiftUI

struct TrainingPlanOverviewView: View {
    @ObservedObject var trainingPlanService: TrainingPlanService
    @State private var selectedPhaseIndex = 0
    @State private var selectedWeekIndex = 1
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
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Today's Workout Section
                if let todayWorkout = trainingPlanService.todayWorkout {
                    TodayWorkoutCard(workout: todayWorkout, formatDate: formatDate)
                        .padding(.horizontal)
                } else if trainingPlanService.currentUserProgram != nil {
                    // No workout today but program is active
                    VStack(spacing: 12) {
                        Text("No workout scheduled for today")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Check your weekly schedule below")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Current Progress
                if let currentPhase = trainingPlanService.getCurrentPhase(),
                   let currentWeekIndex = trainingPlanService.getCurrentWeekIndex() {
                    CurrentProgressCard(
                        currentPhase: currentPhase,
                        currentWeek: currentWeekIndex,
                        totalWeeks: trainingPlanService.currentProgram?.weeks ?? 0
                    )
                    .padding(.horizontal)
                }
                
                // Complete Training Plan Structure
                if trainingPlanService.currentUserProgram != nil && !trainingPlanService.programPhases.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Training Plan Structure")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        // Phase Selector
                        if trainingPlanService.programPhases.count > 1 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(trainingPlanService.programPhases.enumerated()), id: \.element.id) { index, phase in
                                        Button(action: {
                                            selectedPhaseIndex = index
                                            // Reset to first week of selected phase
                                            if let phaseWeeks = trainingPlanService.getWeeksForPhase(phaseId: phase.id).first {
                                                selectedWeekIndex = phaseWeeks.weekIndex
                                            }
                                        }) {
                                            VStack(spacing: 4) {
                                                Text("Phase")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Text("\(phase.phaseIndex)")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                            .background(selectedPhaseIndex == index ? Color.accentColor : Color(.systemGray5))
                                            .foregroundColor(selectedPhaseIndex == index ? .white : .primary)
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Current Phase Info
                        if let currentPhase = trainingPlanService.getCurrentPhase() {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Phase: \(currentPhase.phaseIndex)")
                                    .font(.headline)
                                    .foregroundColor(.accentColor)
                                
                                Text("Weeks: \(currentPhase.weeksCount)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Week Selector
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Week Selection")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(trainingPlanService.programWeeks, id: \.id) { week in
                                        Button(action: {
                                            selectedWeekIndex = week.weekIndex
                                        }) {
                                            VStack(spacing: 4) {
                                                Text("Week")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Text("\(week.weekIndex)")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 16)
                                            .background(selectedWeekIndex == week.weekIndex ? Color.accentColor : Color(.systemGray5))
                                            .foregroundColor(selectedWeekIndex == week.weekIndex ? .white : .primary)
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Week Workouts
                        if let selectedWeek = trainingPlanService.programWeeks.first(where: { $0.weekIndex == selectedWeekIndex }) {
                            let weekWorkouts = trainingPlanService.getWorkoutsForWeek(weekId: selectedWeek.id)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Week \(selectedWeek.weekIndex) Workouts")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                if weekWorkouts.isEmpty {
                                    Text("No workouts found for this week")
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else {
                                    LazyVStack(spacing: 12) {
                                        ForEach(weekWorkouts) { workout in
                                            WeekWorkoutCard(
                                                workout: workout,
                                                onTap: {
                                                    selectedWorkout = workout
                                                    showingWorkoutDetail = true
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                
                // Phase Selector (Alternative view)
                if trainingPlanService.programPhases.count > 1 {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Program Phases")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(trainingPlanService.programPhases.enumerated()), id: \.element.id) { index, phase in
                                    PhaseCard(
                                        phase: phase,
                                        isSelected: selectedPhaseIndex == index,
                                        isCurrent: trainingPlanService.getCurrentPhase()?.id == phase.id
                                    ) {
                                        selectedPhaseIndex = index
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Complete Program Structure (Expandable view)
                if !trainingPlanService.programPhases.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Complete Program Structure")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 16) {
                            ForEach(trainingPlanService.programPhases, id: \.id) { phase in
                                PhaseDetailView(
                                    phase: phase,
                                    weeks: trainingPlanService.getWeeksForPhase(phaseId: phase.id),
                                    workouts: trainingPlanService.programWorkouts,
                                    isExpanded: expandedWeeks.contains(phase.id),
                                    onToggle: {
                                        if expandedWeeks.contains(phase.id) {
                                            expandedWeeks.remove(phase.id)
                                        } else {
                                            expandedWeeks.insert(phase.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
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
            
            // Set initial week selection to current week
            if let currentWeekIndex = trainingPlanService.getCurrentWeekIndex() {
                selectedWeekIndex = currentWeekIndex
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
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
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
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

struct PhaseDetailView: View {
    let phase: ProgramPhase
    let weeks: [ProgramWeek]
    let workouts: [ProgramWorkout]
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Phase Header
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Phase \(phase.phaseIndex)")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("\(phase.weeksCount) weeks")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Weeks Detail
            if isExpanded {
                LazyVStack(spacing: 12) {
                    ForEach(weeks, id: \.id) { week in
                        WeekDetailView(
                            week: week,
                            workouts: getWorkoutsForWeek(weekId: week.id)
                        )
                    }
                }
                .padding(.leading, 20)
            }
        }
    }
    
    private func getWorkoutsForWeek(weekId: String) -> [ProgramWorkout] {
        return workouts.filter { $0.weekId == weekId }.sorted { $0.dayIndex < $1.dayIndex }
    }
}

struct WeekDetailView: View {
    let week: ProgramWeek
    let workouts: [ProgramWorkout]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Week \(week.weekIndex)")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(workouts.count) workouts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if workouts.isEmpty {
                Text("No workouts scheduled")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(workouts) { workout in
                        WorkoutSummaryRow(workout: workout)
                    }
                }
                .padding(.leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct WorkoutSummaryRow: View {
    let workout: ProgramWorkout
    
    var body: some View {
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
        .padding(.vertical, 4)
    }
}

struct TodayWorkoutCard: View {
    let workout: UserWorkout
    let formatDate: (Date) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Workout")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(workout.titleSnapshot)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: workout.status)
            }
            
            HStack {
                Label(formatDate(workout.scheduledDate), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if workout.status == "planned" {
                    Button("Start") {
                        // Start workout logic
                    }
                    .buttonStyle(.borderedProminent)
                } else if workout.status == "in_progress" {
                    Button("Continue") {
                        // Continue workout logic
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WeekWorkoutCard: View {
    let workout: ProgramWorkout
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day \(workout.dayIndex)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(workout.title)
                        .font(.headline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(radius: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .foregroundColor(.white)
            .cornerRadius(6)
    }
    
    private var statusColor: Color {
        switch status {
        case "planned": return .blue
        case "in_progress": return .orange
        case "completed": return .green
        case "skipped": return .gray
        default: return .gray
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
                            
                            LazyVStack(spacing: 12) {
                                ForEach(movementBlocks) { block in
                                    MovementBlockCard(block: block)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
            
            // Placeholder for movement block items
            Text("Movement details will be loaded here")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    TrainingPlanOverviewView(trainingPlanService: TrainingPlanService(supabase: SupabaseManager.shared.client))
}
