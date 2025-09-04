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
                        
                        LazyVStack(spacing: 12) {
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
                        Text("Week Ahead")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        if let nextWorkouts = getNextThreeWorkouts(), !nextWorkouts.isEmpty {
                            LazyVStack(spacing: 20) {
                                ForEach(nextWorkouts) { workout in
                                    WorkoutPreviewCard(
                                        workout: workout,
                                        trainingPlanService: trainingPlanService
                                    )
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            Text("No upcoming workouts scheduled")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                }
                
                // Section 3: Modify Plan Button
                VStack(alignment: .leading, spacing: 16) {
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
    
    private func getNextThreeWorkouts() -> [ProgramWorkout]? {
        guard let currentWeekIndex = trainingPlanService.getCurrentWeekIndex(),
              let currentWeek = trainingPlanService.programWeeks.first(where: { $0.weekIndex == currentWeekIndex }) else {
            return nil
        }
        
        let weekWorkouts = trainingPlanService.getWorkoutsForWeek(weekId: currentWeek.id)
        let remainingWorkouts = weekWorkouts.filter { workout in
            // This would need to be implemented based on your workout completion logic
            // For now, returning all workouts as remaining
            return true
        }
        
        // Return up to 3 workouts
        return Array(remainingWorkouts.prefix(3))
    }
}

// MARK: - Supporting Views

struct PhaseOverviewCard: View {
    let phase: ProgramPhase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
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
                    .frame(width: 10, height: 10)
            }
            
            // Phase-specific descriptions
            Text(phaseDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var phaseColor: Color {
        switch phase.phaseIndex {
        case 1: return .blue
        case 2: return .green
        case 3: return .orange
        default: return .gray
        }
    }
    
    private var phaseDescription: String {
        switch phase.phaseIndex {
        case 1: return "Accelerating recovery through a strong foundation"
        case 2: return "Building resilience and strength"
        case 3: return "Achieving results and high performance"
        default: return "Phase focuses on building foundational strength and movement patterns"
        }
    }
}

struct WorkoutPreviewCard: View {
    let workout: ProgramWorkout
    @ObservedObject var trainingPlanService: TrainingPlanService
    @State private var isExpanded = false
    @State private var workoutBlocks: [ProgramWorkoutBlock]?
    @State private var blockItems: [String: [MovementBlockItem]] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with day and title only - always visible
            HStack {
                Text("Day \(workout.dayIndex): \(workout.title)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Chevron indicator
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.white)
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 24)
            .background(Color(.systemGray5))
            .cornerRadius(16)
            
            // Expanded details - only visible when expanded
            if isExpanded {
                VStack(alignment: .leading, spacing: 20) {
                    if let blocks = workoutBlocks {
                        ForEach(blocks) { block in
                            CollapsibleBlockCard(
                                block: block,
                                blockItems: blockItems[block.id] ?? []
                            )
                        }
                    } else {
                        // Loading state
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading workout details...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
                .padding(.top, 20)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
            }
        }
        .onAppear {
            loadWorkoutBlocks()
        }
        .onChange(of: isExpanded) { _, newValue in
            if newValue && workoutBlocks == nil {
                loadWorkoutBlocks()
            }
        }
    }
    
    private func loadWorkoutBlocks() {
        Task {
            do {
                let blocks = try await trainingPlanService.fetchWorkoutMovementBlocks(workoutId: workout.id)
                await MainActor.run {
                    self.workoutBlocks = blocks
                }
                
                // Load block items for each block
                for block in blocks {
                    let items = try await trainingPlanService.fetchMovementBlockItems(blockId: block.movementBlockId)
                    await MainActor.run {
                        self.blockItems[block.id] = items
                    }
                }
            } catch {
                print("Error loading workout blocks: \(error)")
            }
        }
    }
}

// MARK: - Collapsible Block Card
struct CollapsibleBlockCard: View {
    let block: ProgramWorkoutBlock
    let blockItems: [MovementBlockItem]
    @State private var isBlockExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Block header - always visible
            HStack {
                Text(block.movementBlock?.name ?? "Unknown Block")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Block chevron indicator
                Image(systemName: isBlockExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .animation(.easeInOut(duration: 0.2), value: isBlockExpanded)
            }
            .padding()
            .background(Color(.systemGray4))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray3), lineWidth: 1)
            )
            
            // Block movements - only visible when expanded
            if isBlockExpanded {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(blockItems) { item in
                        MovementTile(
                            movement: item.movement,
                            movementId: item.movementId
                        )
                    }
                }
                .padding(.top, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isBlockExpanded.toggle()
            }
        }
    }
}

// MARK: - Movement Tile
struct MovementTile: View {
    let movement: MovementMinimal?
    let movementId: String
    @State private var fullMovement: Movement?
    @State private var isLoading = true
    
    var body: some View {
        NavigationLink(destination: Group {
            if isLoading {
                VStack {
                    ProgressView()
                    Text("Loading movement details...")
                        .foregroundColor(.secondary)
                }
            } else if let fullMovement = fullMovement {
                MovementDetailView(movement: fullMovement)
            } else {
                Text("Failed to load movement details.")
                    .foregroundColor(.red)
            }
        }) {
            VStack(alignment: .leading, spacing: 6) {
                Text(movement?.name ?? "Unknown Movement")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                if let description = movement?.description, !description.isEmpty {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear(perform: loadFullMovement)
    }
    
    	private func loadFullMovement() {
		guard fullMovement == nil else { return }
		
		// Use movement name instead of UUID for searching
		guard let movementName = movement?.name else {
			print("❌ [MovementTile] No movement name available")
			isLoading = false
			return
		}
		
		print("🔍 [MovementTile] Loading full movement for name: \(movementName)")
		
		Task {
			do {
				let movementService = MovementLibraryService()
				print("🔍 [MovementTile] Calling getAllMovements to find movement...")
				
				// Get all movements and find the one with matching name
				let allMovements = try await movementService.getAllMovements()
				let foundMovement = allMovements.first { $0.name.lowercased() == movementName.lowercased() }
				
				print("🔍 [MovementTile] Found movement: \(foundMovement?.name ?? "nil")")
				
				await MainActor.run {
					self.fullMovement = foundMovement
					self.isLoading = false
					print("✅ [MovementTile] Successfully loaded movement: \(foundMovement?.name ?? "nil")")
				}
			} catch {
				print("❌ [MovementTile] Error loading full movement: \(error)")
				await MainActor.run {
					self.isLoading = false
				}
			}
		}
	}
}





struct WeekAheadCard: View {
    let week: ProgramWeek
    @ObservedObject var trainingPlanService: TrainingPlanService
    @State private var isExpanded = false
    
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
                DisclosureGroup(
                    isExpanded: $isExpanded,
                    content: {
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
                        .padding(.top, 8)
                    },
                    label: {
                        HStack {
                            Text("View Details")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.accentColor)
                            
                            Spacer()
                            
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                    }
                )
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
