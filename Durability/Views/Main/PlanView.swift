import SwiftUI
import Supabase

struct PlanView: View {
    @Binding var showingProfile: Bool
    @State private var expandedPhases: Set<String> = []
    @State private var expandedWeeks: Set<String> = []
    @StateObject private var trainingPlanService: TrainingPlanService
    
    init(showingProfile: Binding<Bool>, supabase: SupabaseClient) {
        self._showingProfile = showingProfile
        self._trainingPlanService = StateObject(wrappedValue: TrainingPlanService(supabase: supabase))
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomLeading) {
                Color.darkSpaceGrey
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Header
                        HStack {
                            Text("Training Plan")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button {
                                showingProfile = true
                            } label: {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Loading State
                        if trainingPlanService.isLoading {
                            ProgressView("Loading training plan...")
                                .foregroundColor(.white)
                                .scaleEffect(1.2)
                                .padding(.vertical, 40)
                        } else if let program = trainingPlanService.currentProgram {
                            // Program Overview
                            ProgramOverviewCard(program: program)
                            
                            // Phases and Weeks
                            if let currentWeek = trainingPlanService.currentWeek {
                                // Show current week workouts
                                CurrentWeekSection(currentWeek: currentWeek)
                            }
                            
                            // Program Structure (Phases and Weeks)
                            ProgramStructureSection(
                                program: program,
                                expandedPhases: $expandedPhases,
                                expandedWeeks: $expandedWeeks
                            )
                            
                        } else {
                            // No active program
                            VStack(spacing: 16) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                                
                                Text("No Active Training Plan")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Contact your coach to get started with a personalized training plan.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .onAppear {
            loadTrainingPlan()
        }
    }
    
    private func loadTrainingPlan() {
        Task {
            do {
                let _ = try await trainingPlanService.fetchActiveProgram()
                if trainingPlanService.currentProgram != nil {
                    let _ = try await trainingPlanService.fetchWeek(weekIndex: 1)
                }
            } catch {
                print("Error loading training plan: \(error)")
            }
        }
    }
}

// MARK: - Program Overview Card
struct ProgramOverviewCard: View {
    let program: Program
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(program.weeks) weeks • \(program.workoutsPerWeek) workouts per week")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            

        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Current Week Section
struct CurrentWeekSection: View {
    let currentWeek: ProgramWeek
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current Week")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Week \(currentWeek.weekIndex)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("Phase Week \(currentWeek.phaseWeekIndex)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Program Structure Section
struct ProgramStructureSection: View {
    let program: Program
    @Binding var expandedPhases: Set<String>
    @Binding var expandedWeeks: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Program Structure")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            // For now, show a simplified structure since we need to fetch phases
            // In the future, this would show actual phases and weeks
            VStack(spacing: 12) {
                ForEach(1...program.weeks, id: \.self) { weekIndex in
                    WeekCard(
                        weekIndex: weekIndex,
                        isExpanded: expandedWeeks.contains("week_\(weekIndex)"),
                        onToggle: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if expandedWeeks.contains("week_\(weekIndex)") {
                                    expandedWeeks.remove("week_\(weekIndex)")
                                } else {
                                    expandedWeeks.insert("week_\(weekIndex)")
                                }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Week Card
struct WeekCard: View {
    let weekIndex: Int
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Week Header
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Week \(weekIndex)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Phase week details")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Content
            if isExpanded {
                Spacer()
                    .frame(height: 8)
                
                VStack(spacing: 16) {
                    // Week Overview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Week Overview")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Week \(weekIndex) focuses on building strength and endurance")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Workout Days
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Workout Days")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { dayIndex in
                                HStack {
                                    Text("Day \(dayIndex)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("Workout details will be loaded")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
}

#Preview {
    PlanView(showingProfile: .constant(false), supabase: SupabaseManager.shared.client)
}
