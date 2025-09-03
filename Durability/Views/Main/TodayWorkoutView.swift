import SwiftUI

struct TodayWorkoutView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showingProfile: Bool
    @State private var showRunner = false
    @State private var showAssessmentPrompt = false
    @State private var showMovementLibrary = false
    @StateObject private var movementLibraryService = MovementLibraryService()
    @State private var availableMovements: [Movement] = []
    @State private var isLoadingMovements = false
    
    // Computed property to get user's first name
    private var userFirstName: String {
        if let firstName = appState.currentUser?.firstName {
            return firstName
        }
        return "there" // Fallback if no name is available
    }
    
    // Computed properties for workout completion
    private var workoutCompletionPercentage: Double {
        // For now, return 0.0 since we don't have real workout data
        // In a real app, this would come from the user's workout progress
        return 0.0
    }
    
    private var workoutCompletionText: String {
        if workoutCompletionPercentage > 0.0 {
            return "Continue"
        } else {
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
                        
                        // Workout Status Header with Completion Percentage and Plan Progress
                        HStack(spacing: 16) {
                            // Left side: Workout progress (75% width)
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
                            .frame(maxWidth: .infinity)
                            
                            // Right side: Phase progress tracker (25% width)
                            VStack(spacing: 8) {
                                Text("Phase Progress")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                ZStack {
                                    // Background circle
                                    Circle()
                                        .stroke(Color(.systemGray4), lineWidth: 4)
                                        .frame(width: 60, height: 60)
                                    
                                    // Progress circle (5/12 = ~42%)
                                    Circle()
                                        .trim(from: 0, to: 5.0/12.0)
                                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                        .frame(width: 60, height: 60)
                                        .rotationEffect(.degrees(-90))
                                    
                                    // Center text
                                    VStack(spacing: 2) {
                                        Text("5")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        Text("/12")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .frame(width: 80)
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        

                        
                        // Workout Structure
                        VStack(alignment: .leading, spacing: 16) {
                            if isLoadingMovements {
                                // Loading state
                                VStack(spacing: 16) {
                                    ForEach(0..<4) { _ in
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
                            } else {
                                WorkoutSection(
                                    title: "Warm Up",
                                    subtitle: "Warm up and prepare your body",
                                    movements: getMovementsForSection("Warm Up"),
                                    isLoading: isLoadingMovements
                                )
                                
                                WorkoutSection(
                                    title: "Strength & Conditioning",
                                    subtitle: "Primary strength movements",
                                    movements: getMovementsForSection("Strength & Conditioning"),
                                    isLoading: isLoadingMovements
                                )
                                
                                WorkoutSection(
                                    title: "Aerobic",
                                    subtitle: "Endurance and conditioning",
                                    movements: getMovementsForSection("Aerobic"),
                                    isLoading: isLoadingMovements
                                )
                                
                                WorkoutSection(
                                    title: "Cool Down",
                                    subtitle: "Cool down and recovery",
                                    movements: getMovementsForSection("Cool Down"),
                                    isLoading: isLoadingMovements
                                )
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
                    await loadMovements()
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
    
    // MARK: - Movement Loading
    
    private func loadMovements() async {
        isLoadingMovements = true
        do {
            availableMovements = try await movementLibraryService.getAllMovements()
            print("Loaded \(availableMovements.count) movements from database")
        } catch {
            print("Error loading movements: \(error)")
            // If database loading fails, we'll use fallback movements
            availableMovements = []
        }
        isLoadingMovements = false
    }
    
    private func getMovementsForSection(_ section: String) -> [Movement] {
        let allMovements = availableMovements
        
        // If no movements loaded yet, return fallback movements
        if allMovements.isEmpty {
            print("No movements loaded, using fallback for \(section)")
            return getFallbackMovements(for: section)
        }
        
        print("Using \(allMovements.count) loaded movements for \(section)")
        
        switch section {
        case "Warm Up":
            // Return movements with high recovery impact for warm-up
            let warmUpMovements = allMovements.filter { $0.recoveryImpactScore > 0.3 }
            let result = Array(warmUpMovements.isEmpty ? allMovements.shuffled().prefix(2) : warmUpMovements.shuffled().prefix(2))
            print("Warm Up: \(result.count) movements")
            return result
        case "Strength & Conditioning":
            // Return movements with high resilience impact for strength
            let strengthMovements = allMovements.filter { $0.resilienceImpactScore > 0.3 }
            let result = Array(strengthMovements.isEmpty ? allMovements.shuffled().prefix(2) : strengthMovements.shuffled().prefix(2))
            print("Strength: \(result.count) movements")
            return result
        case "Aerobic":
            // Return movements with high results impact for aerobic work
            let aerobicMovements = allMovements.filter { $0.resultsImpactScore > 0.3 }
            let result = Array(aerobicMovements.isEmpty ? allMovements.shuffled().prefix(2) : aerobicMovements.shuffled().prefix(2))
            print("Aerobic: \(result.count) movements")
            return result
        case "Cool Down":
            // Return movements with high recovery impact for cool down
            let coolDownMovements = allMovements.filter { $0.recoveryImpactScore > 0.2 }
            let result = Array(coolDownMovements.isEmpty ? allMovements.shuffled().prefix(2) : coolDownMovements.shuffled().prefix(2))
            print("Cool Down: \(result.count) movements")
            return result
        default:
            let result = Array(allMovements.shuffled().prefix(2))
            print("Default: \(result.count) movements")
            return result
        }
    }
    
    private func getFallbackMovements(for section: String) -> [Movement] {
        switch section {
        case "Warm Up":
            return [
                Movement(id: 1, name: "Dynamic Stretching", description: "5-10 minutes of dynamic stretching", videoURL: nil, jointsImpacted: ["ankle", "knee", "hip"], musclesImpacted: ["calves", "hamstrings", "glutes"], superMetricsImpacted: ["mobility"], sportsImpacted: ["general"], intensityOptions: ["light", "moderate"], recoveryImpactScore: 0.8, resilienceImpactScore: 0.2, resultsImpactScore: 0.1),
                Movement(id: 2, name: "Mobility Work", description: "Joint preparation and mobility", videoURL: nil, jointsImpacted: ["shoulder", "spine"], musclesImpacted: ["core", "upper back"], superMetricsImpacted: ["mobility"], sportsImpacted: ["general"], intensityOptions: ["light"], recoveryImpactScore: 0.7, resilienceImpactScore: 0.3, resultsImpactScore: 0.1)
            ]
        case "Strength & Conditioning":
            return [
                Movement(id: 3, name: "Squats", description: "Bodyweight or weighted squats", videoURL: nil, jointsImpacted: ["ankle", "knee", "hip"], musclesImpacted: ["quadriceps", "glutes", "hamstrings"], superMetricsImpacted: ["strength"], sportsImpacted: ["general"], intensityOptions: ["bodyweight", "weighted"], recoveryImpactScore: 0.2, resilienceImpactScore: 0.9, resultsImpactScore: 0.8),
                Movement(id: 4, name: "Push-ups", description: "Standard or modified push-ups", videoURL: nil, jointsImpacted: ["shoulder", "elbow"], musclesImpacted: ["chest", "triceps", "shoulders"], superMetricsImpacted: ["strength"], sportsImpacted: ["general"], intensityOptions: ["modified", "standard", "decline"], recoveryImpactScore: 0.1, resilienceImpactScore: 0.8, resultsImpactScore: 0.7),
                Movement(id: 5, name: "Planks", description: "Core stability exercise", videoURL: nil, jointsImpacted: ["spine"], musclesImpacted: ["core", "shoulders"], superMetricsImpacted: ["stability"], sportsImpacted: ["general"], intensityOptions: ["standard", "side", "reverse"], recoveryImpactScore: 0.3, resilienceImpactScore: 0.7, resultsImpactScore: 0.6)
            ]
        case "Aerobic":
            return [
                Movement(id: 6, name: "Jogging", description: "Light to moderate pace", videoURL: nil, jointsImpacted: ["ankle", "knee", "hip"], musclesImpacted: ["calves", "quadriceps", "hamstrings"], superMetricsImpacted: ["endurance"], sportsImpacted: ["running"], intensityOptions: ["light", "moderate", "intense"], recoveryImpactScore: 0.4, resilienceImpactScore: 0.3, resultsImpactScore: 0.9),
                Movement(id: 7, name: "Cycling", description: "Stationary or outdoor cycling", videoURL: nil, jointsImpacted: ["ankle", "knee", "hip"], musclesImpacted: ["quadriceps", "glutes", "calves"], superMetricsImpacted: ["endurance"], sportsImpacted: ["cycling"], intensityOptions: ["light", "moderate", "intense"], recoveryImpactScore: 0.5, resilienceImpactScore: 0.2, resultsImpactScore: 0.8)
            ]
        case "Cool Down":
            return [
                Movement(id: 8, name: "Static Stretching", description: "Hold stretches for 15-30 seconds", videoURL: nil, jointsImpacted: ["ankle", "knee", "hip", "shoulder"], musclesImpacted: ["calves", "hamstrings", "quadriceps", "chest"], superMetricsImpacted: ["mobility"], sportsImpacted: ["general"], intensityOptions: ["light"], recoveryImpactScore: 0.9, resilienceImpactScore: 0.1, resultsImpactScore: 0.1),
                Movement(id: 9, name: "Deep Breathing", description: "Controlled breathing exercises", videoURL: nil, jointsImpacted: ["ribcage"], musclesImpacted: ["diaphragm", "intercostals"], superMetricsImpacted: ["recovery"], sportsImpacted: ["general"], intensityOptions: ["light"], recoveryImpactScore: 0.8, resilienceImpactScore: 0.1, resultsImpactScore: 0.1)
            ]
        default:
            return [
                Movement(id: 10, name: "General Exercise", description: "Basic movement pattern", videoURL: nil, jointsImpacted: ["general"], musclesImpacted: ["general"], superMetricsImpacted: ["general"], sportsImpacted: ["general"], intensityOptions: ["light", "moderate"], recoveryImpactScore: 0.5, resilienceImpactScore: 0.5, resultsImpactScore: 0.5)
            ]
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



struct WorkoutSection: View {
    let title: String
    let subtitle: String
    let movements: [Movement]
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Movement Cards
            if isLoading {
                // Show loading state
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(0..<2) { _ in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                
                                Spacer()
                                
                                Image(systemName: "circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Movement")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(2)
                            
                            Text("Loading...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                }
            } else if movements.isEmpty {
                // Fallback when no movements are available (shouldn't happen with fallback movements)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(0..<2) { _ in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                
                                Spacer()
                                
                                Image(systemName: "circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("No movements available")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(2)
                            
                            Text("Check back later")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                }
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(movements, id: \.id) { movement in
                        MovementCard(movement: movement)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
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
    TodayWorkoutView(showingProfile: .constant(false))
        .environmentObject(AppState())
}


