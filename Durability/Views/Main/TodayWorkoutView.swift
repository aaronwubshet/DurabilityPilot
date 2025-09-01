import SwiftUI

struct TodayWorkoutView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showingProfile: Bool
    @State private var showRunner = false
    @State private var showAssessmentPrompt = false
    @State private var showMovementLibrary = false
    
    // Computed property to get user's first name
    private var userFirstName: String {
        if let firstName = appState.currentUser?.firstName {
            return firstName
        }
        return "there" // Fallback if no name is available
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
                                    Text("Not Started")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                    
                                    Spacer()
                                    
                                    Text("0%")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                
                                // Progress Bar
                                ProgressView(value: 0, total: 100)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                                    .scaleEffect(x: 1, y: 2, anchor: .center)
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Right side: Plan progress tracker (25% width)
                            VStack(spacing: 8) {
                                Text("Plan Progress")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                ZStack {
                                    // Background circle
                                    Circle()
                                        .stroke(Color(.systemGray4), lineWidth: 4)
                                        .frame(width: 60, height: 60)
                                    
                                    // Progress circle (3/7 = ~43%)
                                    Circle()
                                        .trim(from: 0, to: 3.0/7.0)
                                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                        .frame(width: 60, height: 60)
                                        .rotationEffect(.degrees(-90))
                                    
                                    // Center text
                                    VStack(spacing: 2) {
                                        Text("3")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        Text("/7")
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
                        
                        // Start Workout Button
                        Button {
                            showRunner = true
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
                        
                        // Workout Structure
                        VStack(alignment: .leading, spacing: 16) {
                            WorkoutSection(
                                title: "Warm Up",
                                subtitle: "Warm up and prepare your body",
                                movements: [
                                    PlaceholderMovement(name: "Dynamic Stretching", description: "5-10 minutes", icon: "figure.walk"),
                                    PlaceholderMovement(name: "Mobility Work", description: "Joint preparation", icon: "figure.flexibility")
                                ]
                            )
                            
                            WorkoutSection(
                                title: "Strength & Conditioning",
                                subtitle: "Primary strength movements",
                                movements: [
                                    PlaceholderMovement(name: "Compound Movement", description: "3-4 sets", icon: "figure.strengthtraining.traditional"),
                                    PlaceholderMovement(name: "Accessory Work", description: "2-3 sets", icon: "dumbbell.fill")
                                ]
                            )
                            
                            WorkoutSection(
                                title: "Aerobic",
                                subtitle: "Endurance and conditioning",
                                movements: [
                                    PlaceholderMovement(name: "Cardio Circuit", description: "10-15 minutes", icon: "heart.fill"),
                                    PlaceholderMovement(name: "Interval Training", description: "Work/rest cycles", icon: "timer")
                                ]
                            )
                            
                            WorkoutSection(
                                title: "Cool Down",
                                subtitle: "Cool down and recovery",
                                movements: [
                                    PlaceholderMovement(name: "Static Stretching", description: "5-10 minutes", icon: "figure.mind.and.body"),
                                    PlaceholderMovement(name: "Recovery Protocol", description: "Foam rolling", icon: "figure.rolling")
                                ]
                            )
                        }
                        
                        Spacer()
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
                // No database operations needed for now
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
    let movements: [PlaceholderMovement]
    
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
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(movements, id: \.name) { movement in
                    PlaceholderMovementCard(movement: movement)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

struct PlaceholderMovement {
    let name: String
    let description: String
    let icon: String
}

struct PlaceholderMovementCard: View {
    let movement: PlaceholderMovement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: movement.icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                Image(systemName: "circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(movement.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
            
            Text(movement.description)
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



#Preview {
    TodayWorkoutView(showingProfile: .constant(false))
        .environmentObject(AppState())
}


