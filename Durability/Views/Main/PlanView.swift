import SwiftUI

struct PlanView: View {
    @Binding var showingProfile: Bool
    @State private var expandedDays: Set<Int> = []
    
    // Sample data for the next 7 days
    private let upcomingDays: [TrainingDay] = [
        TrainingDay(
            date: Calendar.current.date(byAdding: .day, value: 0, to: Date())!,
            focus: .recovery,
            breakdown: FocusBreakdown(recovery: 70, resilience: 20, results: 10),
            summary: "Active recovery day focused on mobility and tissue quality",
            movements: [
                "Dynamic Stretching Sequence",
                "Foam Rolling - Lower Body",
                "Gentle Walking or Swimming",
                "Mobility Flow",
                "Breathing Exercises"
            ]
        ),
        TrainingDay(
            date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
            focus: .resilience,
            breakdown: FocusBreakdown(recovery: 20, resilience: 60, results: 20),
            summary: "Build foundational strength and movement patterns",
            movements: [
                "Squat Pattern",
                "Hip Hinge",
                "Push Movement",
                "Pull Movement",
                "Core Stability",
                "Balance Work"
            ]
        ),
        TrainingDay(
            date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
            focus: .results,
            breakdown: FocusBreakdown(recovery: 10, resilience: 30, results: 60),
            summary: "High-intensity training for performance gains",
            movements: [
                "Power Clean",
                "Box Jumps",
                "Sprint Intervals",
                "Medicine Ball Throws",
                "Plyometric Push-ups"
            ]
        ),
        TrainingDay(
            date: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
            focus: .recovery,
            breakdown: FocusBreakdown(recovery: 80, resilience: 15, results: 5),
            summary: "Deep recovery and restoration protocols",
            movements: [
                "Static Stretching",
                "Foam Rolling - Full Body",
                "Light Yoga Flow",
                "Cold Therapy",
                "Meditation"
            ]
        ),
        TrainingDay(
            date: Calendar.current.date(byAdding: .day, value: 4, to: Date())!,
            focus: .resilience,
            breakdown: FocusBreakdown(recovery: 15, resilience: 70, results: 15),
            summary: "Progressive overload and skill development",
            movements: [
                "Deadlift Variations",
                "Overhead Press",
                "Row Variations",
                "Single Leg Work",
                "Rotational Movement"
            ]
        ),
        TrainingDay(
            date: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
            focus: .results,
            breakdown: FocusBreakdown(recovery: 5, resilience: 25, results: 70),
            summary: "Maximal effort and competition preparation",
            movements: [
                "Snatch",
                "Clean and Jerk",
                "Burpee Box Jumps",
                "Wall Balls",
                "Rowing Intervals"
            ]
        ),
        TrainingDay(
            date: Calendar.current.date(byAdding: .day, value: 6, to: Date())!,
            focus: .recovery,
            breakdown: FocusBreakdown(recovery: 90, resilience: 10, results: 0),
            summary: "Complete rest and active recovery",
            movements: [
                "Walking",
                "Swimming",
                "Light Cycling",
                "Stretching",
                "Recovery Protocols"
            ]
        )
    ]
    
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
                        
                        // Days List
                        LazyVStack(spacing: 12) {
                            ForEach(Array(upcomingDays.enumerated()), id: \.offset) { index, day in
                                TrainingDayCard(
                                    day: day,
                                    isExpanded: expandedDays.contains(index),
                                    onToggle: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            if expandedDays.contains(index) {
                                                expandedDays.remove(index)
                                            } else {
                                                expandedDays.insert(index)
                                            }
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
        }
    }
    
    private func formatWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

struct TrainingDayCard: View {
    let day: TrainingDay
    let isExpanded: Bool
    let onToggle: () -> Void
    
    private func formatWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func focusColor(_ focus: TrainingFocus) -> Color {
        switch focus {
        case .recovery:
            return .blue
        case .resilience:
            return .green
        case .results:
            return .orange
        }
    }
    
    private func focusIcon(_ focus: TrainingFocus) -> String {
        switch focus {
        case .recovery:
            return "heart.fill"
        case .resilience:
            return "shield.fill"
        case .results:
            return "target"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Day Header
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatDate(day.date))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(formatWeekday(day.date))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Image(systemName: focusIcon(day.focus))
                            .foregroundColor(focusColor(day.focus))
                        
                        Text(day.focus.rawValue.capitalized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(focusColor(day.focus))
                    }
                    
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
                // Add spacing between date card and expanded content
                Spacer()
                    .frame(height: 8)
                
                VStack(spacing: 16) {
                    // Day Goal
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Day Goal")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(day.summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Focus Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Focus Breakdown")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 8) {
                            FocusBreakdownRow(
                                label: "Recovery",
                                percentage: day.breakdown.recovery,
                                color: .blue
                            )
                            
                            FocusBreakdownRow(
                                label: "Resilience",
                                percentage: day.breakdown.resilience,
                                color: .green
                            )
                            
                            FocusBreakdownRow(
                                label: "Results",
                                percentage: day.breakdown.results,
                                color: .orange
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Movements
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Movements")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        // Split movements into columns with max 3 per column
                        let movements = day.movements
                        let leftColumn = Array(movements.prefix(3))
                        let rightColumn = Array(movements.dropFirst(3))
                        
                        HStack(alignment: .top, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(leftColumn, id: \.self) { movement in
                                    HStack(spacing: 8) {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .foregroundColor(.accentColor)
                                        
                                        Text(movement)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            if !rightColumn.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(rightColumn, id: \.self) { movement in
                                        HStack(spacing: 8) {
                                            Image(systemName: "circle.fill")
                                                .font(.system(size: 6))
                                                .foregroundColor(.accentColor)
                                            
                                            Text(movement)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            
                            Spacer()
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

struct FocusBreakdownRow: View {
    let label: String
    let percentage: Int
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            ProgressView(value: Double(percentage), total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(y: 0.8)
            
            Text("\(percentage)%")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 35, alignment: .trailing)
        }
    }
}

// MARK: - Data Models

struct TrainingDay {
    let date: Date
    let focus: TrainingFocus
    let breakdown: FocusBreakdown
    let summary: String
    let movements: [String]
}

struct FocusBreakdown {
    let recovery: Int
    let resilience: Int
    let results: Int
}

enum TrainingFocus: String, CaseIterable {
    case recovery = "recovery"
    case resilience = "resilience"
    case results = "results"
}

// MARK: - Color Extensions

extension Color {
    static let cardBackground = Color(red: 0.15, green: 0.15, blue: 0.2)
}

#Preview {
    PlanView(showingProfile: .constant(false))
}
