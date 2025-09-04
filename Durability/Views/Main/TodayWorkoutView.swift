import SwiftUI
import Supabase

struct TodayWorkoutView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showingProfile: Bool
    @State private var showRunner = false
    @State private var showAssessmentPrompt = false
    @State private var showMovementLibrary = false
    @StateObject private var trainingPlanService: TrainingPlanService
    @State private var todayWorkout: UserWorkout?
    @State private var workoutBlocks: [ProgramWorkoutBlock] = []
    @State private var blockItems: [String: [MovementBlockItem]] = [:]
    @State private var isLoadingWorkout = false
    
    init(showingProfile: Binding<Bool>, supabase: SupabaseClient) {
        self._showingProfile = showingProfile
        self._trainingPlanService = StateObject(wrappedValue: TrainingPlanService(supabase: supabase))
    }
    
    // Computed property to get user's first name
    private var userFirstName: String {
        if let firstName = appState.currentUser?.firstName {
            return firstName
        }
        return "there" // Fallback if no name is available
    }
    
    // Computed properties for workout completion
    private var workoutCompletionPercentage: Double {
        guard let workout = todayWorkout else { return 0.0 }
        
        // Calculate completion based on workout status
        switch workout.status.lowercased() {
        case "completed":
            return 1.0
        case "in_progress":
            return 0.5 // Assume 50% if in progress
        default:
            return 0.0
        }
    }
    
    private var workoutCompletionText: String {
        guard let workout = todayWorkout else { return "Get Started" }
        
        switch workout.status.lowercased() {
        case "completed":
            return "Completed"
        case "in_progress":
            return "Continue"
        default:
            return "Get Started"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomLeading) {
                Color.darkSpaceGrey
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Day Theme Header
                        VStack(spacing: 8) {
                            // Personalized Greeting
                            HStack {
                                Text("Hi \(userFirstName), today's focus is \(getDayTheme().capitalized)")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: themeIcon(for: getDayTheme()))
                                    .foregroundColor(themeColor(for: getDayTheme()))
                                    .font(.title2)
                            }
                            
                            Text(themeDescription(for: getDayTheme()))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        
                        // Workout Status Header with Completion Percentage
                        VStack(spacing: 12) {
                            HStack {
                                HStack(spacing: 8) {
                                    Text(workoutCompletionText)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                    
                                    // Small play button
                                    Button(action: {
                                        showRunner = true
                                    }) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.orange)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                Spacer()
                                
                                Text("\(Int(workoutCompletionPercentage * 100))%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            // Progress Bar
                            ProgressView(value: workoutCompletionPercentage, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        

                        
                        // Workout Structure
                        VStack(alignment: .leading, spacing: 16) {
                            if isLoadingWorkout {
                                // Loading state
                                VStack(spacing: 16) {
                                    ForEach(0..<3) { _ in
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                Rectangle()
                                                    .fill(Color(.systemGray4))
                                                    .frame(width: 100, height: 20)
                                                    .cornerRadius(4)
                                                Spacer()
                                            }
                                            HStack {
                                                Rectangle()
                                                    .fill(Color(.systemGray5))
                                                    .frame(width: 150, height: 16)
                                                    .cornerRadius(4)
                                                Spacer()
                                            }
                                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                                                ForEach(0..<2) { _ in
                                                    Rectangle()
                                                        .fill(Color(.systemGray6))
                                                        .frame(height: 80)
                                                        .cornerRadius(8)
                                                }
                                            }
                                        }
                                        .padding()
                                        .background(Color.cardBackground)
                                        .cornerRadius(12)
                                    }
                                }
                            } else if todayWorkout == nil {
                                VStack(spacing: 16) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text("No workout scheduled for today")
                                        .font(.headline)
                                    Text("Check your training plan or contact your coach")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Button("Retry") {
                                        Task {
                                            await loadTodaysWorkout()
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                            } else if workoutBlocks.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "figure.walk")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text("Workout details loading...")
                                        .font(.headline)
                                    Text("Please wait while we load your workout")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                            } else {
                                // Display actual workout blocks
                                ForEach(workoutBlocks) { block in
                                    TodayWorkoutBlockSection(
                                        block: block,
                                        blockItems: blockItems[block.id] ?? []
                                    )
                                }
                            }
                        }
                        
                        // Movement Library Button at bottom
                        Button(action: {
                            showMovementLibrary = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                
                                Text("Movement Library")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Open Movement Library")
                        
                        Spacer()
                    }
                    .padding()
                }
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
                Task {
                    await loadTodaysWorkout()
                }
            }
        }
        .sheet(isPresented: $showMovementLibrary) {
            MovementLibraryView()
        }
        .sheet(isPresented: $showRunner) {
            // For now, show a placeholder since we don't have real workout data
            Text("Workout Runner - Coming Soon")
                .font(.title)
                .padding()
        }
    }
    
    // MARK: - Workout Loading
    
    private func loadTodaysWorkout() async {
        isLoadingWorkout = true
        do {
            print("🔍 [TodayWorkoutView] Starting to load today's workout...")
            
            // First ensure we have the user's program
            let _ = try await trainingPlanService.fetchActiveUserProgram()
            print("🔍 [TodayWorkoutView] User program loaded")
            
            // Fetch today's workout
            let workout = try await trainingPlanService.fetchTodayWorkout()
            print("🔍 [TodayWorkoutView] Today's workout fetched: \(workout?.titleSnapshot ?? "No workout")")
            
            await MainActor.run {
                self.todayWorkout = workout
            }
            
            // If we have a workout, load its blocks and movements
            if let workout = workout {
                print("🔍 [TodayWorkoutView] Loading workout details...")
                await loadWorkoutDetails(workout: workout)
            } else {
                print("🔍 [TodayWorkoutView] No workout found for today")
            }
            
            print("✅ [TodayWorkoutView] Loaded today's workout: \(workout?.titleSnapshot ?? "No workout")")
        } catch {
            print("❌ [TodayWorkoutView] Error loading today's workout: \(error)")
            await MainActor.run {
                self.todayWorkout = nil
                self.workoutBlocks = []
                self.blockItems = [:]
            }
        }
        isLoadingWorkout = false
    }
    
    private func loadWorkoutDetails(workout: UserWorkout) async {
        do {
            print("🔍 [TodayWorkoutView] Loading workout details for: \(workout.titleSnapshot)")
            print("🔍 [TodayWorkoutView] Workout dayIndex: \(workout.dayIndex)")
            print("🔍 [TodayWorkoutView] Workout weekIndex: \(workout.weekIndex)")
            
            // Get the program ID from the user program
            guard let userProgram = workout.userProgram else {
                print("❌ [TodayWorkoutView] No userProgram found in workout")
                return
            }
            
            let programId = userProgram.programId
            print("🔍 [TodayWorkoutView] Program ID: \(programId)")
            
            // First, ensure we have the complete program structure
            if trainingPlanService.programWeeks.isEmpty || trainingPlanService.programWorkouts.isEmpty {
                print("🔍 [TodayWorkoutView] Program structure not loaded, fetching complete structure...")
                let _ = try await trainingPlanService.fetchCompleteProgramStructure(programId: programId)
            }
            
            print("🔍 [TodayWorkoutView] Program weeks count: \(trainingPlanService.programWeeks.count)")
            print("🔍 [TodayWorkoutView] Program workouts count: \(trainingPlanService.programWorkouts.count)")
            
            // Get the corresponding program workout to fetch blocks
            guard let currentWeekIndex = trainingPlanService.getCurrentWeekIndex() else {
                print("❌ [TodayWorkoutView] Could not get current week index")
                return
            }
            
            print("🔍 [TodayWorkoutView] Current week index: \(currentWeekIndex)")
            
            guard let currentWeek = trainingPlanService.programWeeks.first(where: { $0.weekIndex == currentWeekIndex }) else {
                print("❌ [TodayWorkoutView] Could not find current week")
                return
            }
            
            print("🔍 [TodayWorkoutView] Current week ID: \(currentWeek.id)")
            
            let weekWorkouts = trainingPlanService.getWorkoutsForWeek(weekId: currentWeek.id)
            print("🔍 [TodayWorkoutView] Week workouts count: \(weekWorkouts.count)")
            
            guard let programWorkout = weekWorkouts.first(where: { $0.dayIndex == workout.dayIndex }) else {
                print("❌ [TodayWorkoutView] Could not find program workout for day \(workout.dayIndex)")
                print("🔍 [TodayWorkoutView] Available day indices: \(weekWorkouts.map { $0.dayIndex })")
                return
            }
            
            print("🔍 [TodayWorkoutView] Found program workout: \(programWorkout.title) (ID: \(programWorkout.id))")
            
            // Fetch workout blocks
            let blocks = try await trainingPlanService.fetchWorkoutMovementBlocks(workoutId: programWorkout.id)
            print("🔍 [TodayWorkoutView] Fetched \(blocks.count) workout blocks")
            
            await MainActor.run {
                self.workoutBlocks = blocks
            }
            
            // Load block items for each block
            for block in blocks {
                print("🔍 [TodayWorkoutView] Loading items for block: \(block.movementBlock?.name ?? "Unknown")")
                let items = try await trainingPlanService.fetchMovementBlockItems(blockId: block.movementBlockId)
                print("🔍 [TodayWorkoutView] Loaded \(items.count) items for block")
                await MainActor.run {
                    self.blockItems[block.id] = items
                }
            }
            
            print("✅ [TodayWorkoutView] Successfully loaded \(blocks.count) workout blocks with movements")
        } catch {
            print("❌ [TodayWorkoutView] Error loading workout details: \(error)")
        }
    }
    

    
    // MARK: - Theme Helper Functions
    
    private func getDayTheme() -> String {
        // For now, cycle through themes based on day of week
        // In a real app, this would come from the user's training plan
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        switch weekday {
        case 1, 4, 7: // Sunday, Wednesday, Saturday
            return "recovery"
        case 2, 5: // Monday, Thursday
            return "resilience"
        case 3, 6: // Tuesday, Friday
            return "results"
        default:
            return "recovery"
        }
    }
    
    private func themeIcon(for theme: String) -> String {
        switch theme {
        case "recovery":
            return "heart.fill"
        case "resilience":
            return "shield.fill"
        case "results":
            return "target"
        default:
            return "heart.fill"
        }
    }
    
    private func themeColor(for theme: String) -> Color {
        switch theme {
        case "recovery":
            return .blue
        case "resilience":
            return .green
        case "results":
            return .orange
        default:
            return .blue
        }
    }
    
    private func themeDescription(for theme: String) -> String {
        switch theme {
        case "recovery":
            return "Focus on active recovery, mobility work, and tissue quality to support your overall training."
        case "resilience":
            return "Build foundational strength and movement patterns to improve your durability and resilience."
        case "results":
            return "High-intensity training focused on performance gains and pushing your limits."
        default:
            return "Focus on active recovery, mobility work, and tissue quality to support your overall training."
        }
    }
}



struct TodayWorkoutBlockSection: View {
    let block: ProgramWorkoutBlock
    let blockItems: [MovementBlockItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Block Header
            VStack(alignment: .leading, spacing: 4) {
                Text(block.movementBlock?.name ?? "Workout Block")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(blockItems.count) movements")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Movement Cards
            if blockItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                    Text("No movements in this block")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(blockItems) { item in
                        TodayMovementCard(movementItem: item)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

struct TodayMovementCard: View {
    let movementItem: MovementBlockItem
    
    // Generate different icons for variety
    private func getMovementIcon() -> String {
        let icons = [
            "figure.walk",
            "figure.run",
            "figure.strengthtraining.traditional",
            "figure.core.training",
            "figure.flexibility",
            "figure.mixed.cardio",
            "figure.outdoor.cycle",
            "figure.yoga"
        ]
        
        // Use movement ID to consistently assign icons
        let iconIndex = abs(movementItem.id.hashValue) % icons.count
        return icons[iconIndex]
    }
    
    private var movementDescription: String {
        if let description = movementItem.movement?.description, !description.isEmpty {
            return description
        }
        return "Training movement"
    }
    
    var body: some View {
        NavigationLink(destination: Group {
            // For now, show a placeholder since we need to load full movement details
            VStack {
                Text("Movement Details")
                    .font(.title)
                    .padding()
                Text(movementItem.movement?.name ?? "Unknown Movement")
                    .font(.headline)
                    .padding()
                Text("Full movement details coming soon")
                    .foregroundColor(.secondary)
            }
        }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    // Different icons for variety
                    Image(systemName: getMovementIcon())
                        .font(.title2)
                        .foregroundColor(.electricGreen)
                    
                    Spacer()
                    
                    // Show completion status with better contrast
                    Image(systemName: "circle")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Text(movementItem.movement?.name ?? "Unknown Movement")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(movementDescription)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                
                // Add spacer to ensure consistent height
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120, alignment: .leading)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.2, blue: 0.3),
                        Color(red: 0.15, green: 0.15, blue: 0.25)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MovementCard: View {
    let movement: Movement
    
    // Generate different icons for variety
    private func getMovementIcon() -> String {
        let icons = [
            "figure.walk",
            "figure.run",
            "figure.strengthtraining.traditional",
            "figure.core.training",
            "figure.flexibility",
            "figure.mixed.cardio",
            "figure.outdoor.cycle",
            "figure.yoga"
        ]
        
        // Use movement ID to consistently assign icons
        let iconIndex = abs(movement.id) % icons.count
        return icons[iconIndex]
    }
    
    private var movementDescription: String {
        // Create a description based on the movement's impact scores
        var descriptions: [String] = []
        
        if movement.recoveryImpactScore > 0.5 {
            descriptions.append("Recovery")
        }
        if movement.resilienceImpactScore > 0.5 {
            descriptions.append("Strength")
        }
        if movement.resultsImpactScore > 0.5 {
            descriptions.append("Cardio")
        }
        
        if descriptions.isEmpty {
            return "General movement"
        } else {
            return descriptions.joined(separator: " • ")
        }
    }
    
    var body: some View {
        NavigationLink(destination: MovementDetailView(movement: movement)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    // Different icons for variety
                    Image(systemName: getMovementIcon())
                        .font(.title2)
                        .foregroundColor(.electricGreen)
                    
                    Spacer()
                    
                    // Show completion status with better contrast
                    Image(systemName: "circle")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Text(movement.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(movementDescription)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                
                // Add spacer to ensure consistent height
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120, alignment: .leading)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.2, blue: 0.3),
                        Color(red: 0.15, green: 0.15, blue: 0.25)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}



#Preview {
    TodayWorkoutView(
        showingProfile: .constant(false),
        supabase: SupabaseClient(
            supabaseURL: URL(string: "https://example.com")!,
            supabaseKey: "key"
        )
    )
    .environmentObject(AppState())
}


