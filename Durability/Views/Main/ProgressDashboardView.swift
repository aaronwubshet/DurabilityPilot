import SwiftUI

struct ProgressDashboardView: View {
    @StateObject private var viewModel = ProgressViewModel()
    @EnvironmentObject var appState: AppState
    @Binding var showingProfile: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkSpaceGrey
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        if viewModel.isLoading {
                            ProgressView("Loading progress...")
                                .foregroundColor(.lightText)
                        } else if let latestResult = viewModel.latestAssessmentResult {
                            // Durability Score Card
                            DurabilityScoreCard(score: latestResult.durabilityScore)
                            
                            // Progress History Card (Line Chart)
                            ProgressHistoryCard(
                                assessmentHistory: viewModel.assessmentHistory,
                                assessmentResultsHistory: viewModel.assessmentResultsHistory
                            )
                            
                            // Workout Completion Calendar
                            WorkoutCompletionCalendarView(viewModel: viewModel)
                            
                            // Super Metrics Card
                            ProgressSuperMetricsCard(
                                results: viewModel.latestAssessmentResult,
                                history: viewModel.assessmentHistory
                            )
                            
                            // Analytics Button
                            AnalyticsButton()
                            

                            
                        } else {
                            EmptyStateView()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Progress Tracking")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button("Re-Assess") {
                            Task {
                                await resetForRetake()
                            }
                        }
                        .foregroundColor(.electricGreen)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        
                        Button(action: {
                            showingProfile = true
                        }) {
                            Image(systemName: "person.circle")
                                .foregroundColor(.lightText)
                        }
                    }
                }
            }
            .onAppear {
                viewModel.loadProgressData(appState: appState)
            }
        }
    }
    
    /// Reset app state to allow a fresh assessment retake
    private func resetForRetake() async {
        // Set app flow state to start re-assessment
        await MainActor.run {
            appState.appFlowState = .assessment
            appState.currentAssessmentResults = []
        }
        
        // Update the user profile in the database to mark assessment as not completed
        if appState.authService.user?.id != nil {
            do {
                var updatedProfile = appState.currentUser
                updatedProfile?.assessmentCompleted = false
                updatedProfile?.updatedAt = Date()
                
                if let profile = updatedProfile {
                    try await appState.profileService.updateProfile(profile)
                    
                    await MainActor.run {
                        appState.currentUser = profile
                    }
                }
            } catch {
                // Handle error silently
            }
        }
    }
}

// MARK: - Supporting Views

struct DurabilityScoreCard: View {
    let score: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Durability Score")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.lightText)
                    
                    Text("Your overall fitness and injury resilience")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(score * 100))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor(score))
                    
                    Text("/ 100")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(scoreCategory(score))
                        .font(.subheadline)
                        .foregroundColor(scoreColor(score))
                    
                    Spacer()
                    
                    Text("\(Int(score * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(scoreColor(score))
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(scoreColor(score))
                            .frame(width: geometry.size.width * score, height: 8)
                            .animation(.easeOut(duration: 1.0), value: score)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(20)
        .background(Color.lightSpaceGrey)
        .cornerRadius(16)
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0.75...: return .electricGreen  // 75-100: Green
        case 0.5..<0.75: return .yellow     // 50-75: Yellow
        case 0.25..<0.5: return .orange     // 25-50: Orange
        default: return .red                 // 0-25: Red
        }
    }
    
    private func scoreCategory(_ score: Double) -> String {
        switch score {
        case 0.75...: return "Excellent"      // 75-100: Green
        case 0.5..<0.75: return "Good"       // 50-75: Yellow
        case 0.25..<0.5: return "Fair"       // 25-50: Orange
        default: return "Needs Improvement"   // 0-25: Red
        }
    }
}

struct ProgressSuperMetricsCard: View {
    let results: AssessmentResult?
    let history: [Assessment]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Super Metrics")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.lightText)
            
            if let results = results {
                // Placeholder for radar chart (we'll implement this next)
                SuperMetricsRadarChartView(results: results, history: history)
            } else {
                Text("No metrics data available")
                    .foregroundColor(.secondaryText)
            }
        }
        .padding(20)
        .background(Color.lightSpaceGrey)
        .cornerRadius(16)
    }
}

struct ProgressHistoryCard: View {
    let assessmentHistory: [Assessment]
    let assessmentResultsHistory: [AssessmentResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Progress History")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.lightText)
                
                Spacer()
                
                // Show data range info
                if !assessmentResultsHistory.isEmpty {
                    Text(dataRangeText)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }
            
            // Standardized Line Chart
            StandardizedLineChartView(
                data: getChartData(),
                title: "Durability Score"
            )
        }
        .padding(20)
        .background(Color.lightSpaceGrey)
        .cornerRadius(16)
    }
    
    private var dataRangeText: String {
        let chartData = getChartData()
        guard !chartData.isEmpty else { return "" }
        
        let calendar = Calendar.current
        let firstDate = chartData.first?.date ?? Date()
        let lastDate = chartData.last?.date ?? Date()
        
        let daysBetween = calendar.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0
        
        if daysBetween == 0 {
            return "Today"
        } else if daysBetween <= 7 {
            return "Last \(daysBetween + 1) days"
        } else {
            return "Last 7 days"
        }
    }
    
    private func getChartData() -> [ChartDataPoint] {
        // Create data points with dates
        var dataPoints: [ChartDataPoint] = []
        
        for result in assessmentResultsHistory {
            guard let assessment = assessmentHistory.first(where: { $0.assessmentId == result.assessmentId }) else {
                continue
            }
            
            let dataPoint = ChartDataPoint(
                x: 0, // Will be calculated based on date
                y: result.durabilityScore * 100, // Convert to percentage
                date: assessment.createdAt,
                label: "Assessment \(String(assessment.assessmentId ?? 0).prefix(8))"
            )
            dataPoints.append(dataPoint)
        }
        
        // Sort by date (newest first)
        dataPoints.sort { $0.date > $1.date }
        
        // If we have more than 7 days of data, only show the last 7 days
        if dataPoints.count > 7 {
            dataPoints = Array(dataPoints.prefix(7))
        }
        
        // Reverse to show oldest to newest (left to right)
        dataPoints.reverse()
        
        // Create final data points with correct x-axis positions
        return dataPoints.enumerated().map { index, dataPoint in
            ChartDataPoint(
                x: Double(index),
                y: dataPoint.y,
                date: dataPoint.date,
                label: dataPoint.label
            )
        }
    }
}

struct RecentAssessmentsCard: View {
    let assessmentHistory: [Assessment]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Assessments")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.lightText)
            
            if assessmentHistory.isEmpty {
                Text("No assessments yet")
                    .foregroundColor(.secondaryText)
            } else {
                ForEach(assessmentHistory.prefix(3), id: \.assessmentId) { assessment in
                    HStack {
                        Text("Assessment #\(String(assessment.assessmentId ?? 0).prefix(8))")
                            .font(.subheadline)
                            .foregroundColor(.lightText)
                        
                        Spacer()
                        
                        Text("\(Int((assessment.assessmentId ?? 0) % 100))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.electricGreen)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(20)
        .background(Color.lightSpaceGrey)
        .cornerRadius(16)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.electricGreen)
            
            Text("No Progress Data")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.lightText)
            
            Text("Complete your first assessment to start tracking your progress")
                .font(.body)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}





// MARK: - Analytics Button
struct AnalyticsButton: View {
    var body: some View {
        NavigationLink(destination: AnalyticsView()) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.electricGreen)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text("View Analytics")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("Detailed insights and metrics")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryText)
            }
            .padding(20)
            .background(Color.lightSpaceGrey)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Workout Completion Calendar View
struct WorkoutCompletionCalendarView: View {
    @ObservedObject var viewModel: ProgressViewModel
    @State private var selectedMonth: Date = {
        // Set default to June 2025 to show the color-coded data
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2025
        components.month = 6
        components.day = 1
        return calendar.date(from: components) ?? Date()
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Month selector
            HStack {
                Text(selectedMonth, style: .date)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.accentColor)
                }
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                // Day headers
                ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondaryText)
                        .frame(height: 20)
                }
                
                // Calendar days
                ForEach(Array(calendarDays.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        WorkoutDayView(
                            date: date,
                            status: viewModel.getDailyWorkoutStatus(for: date),
                            isCurrentMonth: Calendar.current.isDate(date, equalTo: selectedMonth, toGranularity: .month)
                        )
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
            .padding(.horizontal)
            
            // Color legend
            HStack(spacing: 16) {
                LegendItem(color: .red, text: "<40%")
                LegendItem(color: .orange, text: "40-60%")
                LegendItem(color: .yellow, text: "60-80%")
                LegendItem(color: .green, text: "80-100%")
                LegendItem(color: .gray, text: "No workout")
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.lightSpaceGrey)
        .cornerRadius(16)
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }
    
    private var calendarDays: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        
        // Get the first day of the month and the day of week it falls on
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let offsetDays = firstWeekday - 1 // Adjust for Sunday = 1
        
        // Get the number of days in the month
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
        
        var days: [Date?] = []
        
        // Add empty cells for days before the first of the month
        for _ in 0..<offsetDays {
            days.append(nil)
        }
        
        // Add all days of the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        // Pad to complete the last week if necessary
        let remainingCells = 7 - (days.count % 7)
        if remainingCells < 7 {
            for _ in 0..<remainingCells {
                days.append(nil)
            }
        }
        
        return days
    }
    
    private func previousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
}

// MARK: - Individual Day View
struct WorkoutDayView: View {
    let date: Date
    let status: DailyWorkoutStatus
    let isCurrentMonth: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            // Date number
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(isCurrentMonth ? .primary : .secondary)
            
            // Activity ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                // Progress ring
                if status.hasWorkout {
                    Circle()
                        .trim(from: 0, to: status.completionPercentage)
                        .stroke(status.ringColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(-90))
                    
                    // Center dot for completed workouts
                    Circle()
                        .fill(status.ringColor)
                        .frame(width: 4, height: 4)
                }
            }
        }
        .frame(height: 40)
    }
}

// MARK: - Legend Item View
struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondaryText)
        }
    }
}

#Preview {
    ProgressDashboardView(showingProfile: .constant(false))
        .environmentObject(AppState())
}




// MARK: - Standardized Line Chart View
struct StandardizedLineChartView: View {
    let data: [ChartDataPoint]
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.lightText)
            
            if data.count < 2 {
                // Show placeholder for insufficient data
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 120)
                    .overlay(
                        Text("Need at least 2 assessments to show trend")
                            .foregroundColor(.secondaryText)
                            .font(.caption)
                    )
            } else {
                // Chart with proper axis labels
                VStack(spacing: 4) {
                    // Chart area
                    GeometryReader { geometry in
                ZStack {
                    // Background grid
                            StandardizedChartGrid(data: data, geometry: geometry)
                    
                    // Line path
                            StandardizedChartLine(data: data, geometry: geometry)
                            
                            // Data points
                            StandardizedChartPoints(data: data, geometry: geometry)
                        }
                    }
                    .frame(height: 240)
                    
                    // X-axis labels (dates)
                    HStack {
                        ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                            Text(formatDate(point.date))
                                .font(.caption2)
                                .foregroundColor(.secondaryText)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    

}

struct StandardizedChartGrid: View {
    let data: [ChartDataPoint]
    let geometry: GeometryProxy
    
    var body: some View {
        // Fixed y-axis range from 0 to 100
        let maxY: Double = 100
        let minY: Double = 0
        
        VStack(spacing: 0) {
            ForEach(0..<5, id: \.self) { index in
                Divider()
                    .background(Color.gray.opacity(0.2))
                    .frame(height: 1)
                
                if index < 4 {
                    Spacer()
                }
            }
        }
        .overlay(
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<5, id: \.self) { index in
                        let value = maxY - (maxY - minY) * Double(index) / 4
                        Text("\(Int(value))")
                            .font(.caption2)
                            .foregroundColor(.secondaryText)
                            .frame(height: geometry.size.height / 5)
                    }
                }
                .frame(width: 35) // Increased width for better spacing
                
                Spacer()
            }
        )
    }
}

struct StandardizedChartLine: View {
    let data: [ChartDataPoint]
    let geometry: GeometryProxy
    
    var body: some View {
        // Fixed y-axis range from 0 to 100
        let maxY: Double = 100
        let minY: Double = 0
        let maxX = Double(data.count - 1)
        
        // Add padding to prevent overlap with y-axis
        let chartWidth = geometry.size.width - 40 // 35 for y-axis + 5 padding
        let chartStartX: CGFloat = 40 // Start after y-axis
        
        Path { path in
            for (index, point) in data.enumerated() {
                let x = chartStartX + (point.x / maxX) * chartWidth
                let y = geometry.size.height - ((point.y - minY) / (maxY - minY)) * geometry.size.height
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .stroke(Color.electricGreen, lineWidth: 2)
    }
}

struct StandardizedChartPoints: View {
    let data: [ChartDataPoint]
    let geometry: GeometryProxy
    
    var body: some View {
        // Fixed y-axis range from 0 to 100
        let maxY: Double = 100
        let minY: Double = 0
        let maxX = Double(data.count - 1)
        
        // Add padding to prevent overlap with y-axis
        let chartWidth = geometry.size.width - 40 // 35 for y-axis + 5 padding
        let chartStartX: CGFloat = 40 // Start after y-axis
        
        ForEach(data) { point in
            let x = chartStartX + (point.x / maxX) * chartWidth
            let y = geometry.size.height - ((point.y - minY) / (maxY - minY)) * geometry.size.height
            
            Circle()
                .fill(Color.electricGreen)
                .frame(width: 6, height: 6)
                .position(x: x, y: y)
        }
    }
}

