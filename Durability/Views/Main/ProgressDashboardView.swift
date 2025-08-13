import SwiftUI

struct ProgressDashboardView: View {
    @StateObject private var viewModel = ProgressViewModel()
    @EnvironmentObject var appState: AppState
    @State private var selectedTimePeriod: TimePeriod = .month

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
                            
                            // Super Metrics Card
                            ProgressSuperMetricsCard(
                                results: viewModel.latestAssessmentResult,
                                history: viewModel.assessmentHistory
                            )
                            
                            // Progress History Card
                            ProgressHistoryCard(
                                selectedTimePeriod: $selectedTimePeriod,
                                assessmentHistory: viewModel.assessmentHistory,
                                assessmentResultsHistory: viewModel.assessmentResultsHistory
                            )
                            
                            // Recent Assessments Card
                            RecentAssessmentsCard(assessmentHistory: viewModel.assessmentHistory)
                            
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
                            // TODO: Navigate to assessment flow
                        }
                        .foregroundColor(.electricGreen)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        
                        NavigationLink(destination: ProfileView()) {
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
                        .foregroundColor(.electricGreen)
                    
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
                        .foregroundColor(.electricGreen)
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
        case 0.8...: return .electricGreen
        case 0.6..<0.8: return .orange
        case 0.4..<0.6: return .yellow
        default: return .red
        }
    }
    
    private func scoreCategory(_ score: Double) -> String {
        switch score {
        case 0.8...: return "Excellent"
        case 0.6..<0.8: return "Good"
        case 0.4..<0.6: return "Fair"
        default: return "Needs Improvement"
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
    @Binding var selectedTimePeriod: TimePeriod
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
                
                // Time period selector
                HStack(spacing: 8) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Button(period.displayName) {
                            selectedTimePeriod = period
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedTimePeriod == period ? Color.electricGreen : Color.clear)
                        .foregroundColor(selectedTimePeriod == period ? .darkSpaceGrey : .secondaryText)
                        .cornerRadius(8)
                    }
                }
            }
            
            // Progress Chart
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Durability Score")
                        .font(.subheadline)
                        .foregroundColor(.lightText)
                    
                    Spacer()
                    
                    if let latestResult = assessmentResultsHistory.first {
                        Text("\(Int(latestResult.durabilityScore * 100))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.electricGreen)
                    }
                }
                
                // Line Chart
                if assessmentResultsHistory.isEmpty {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 120)
                        .overlay(
                            Text("No data available")
                                .foregroundColor(.secondaryText)
                        )
                } else {
                    LineChartView(
                        data: getChartData(),
                        selectedTimePeriod: selectedTimePeriod
                    )
                    .frame(height: 120)
                }
            }
        }
        .padding(20)
        .background(Color.lightSpaceGrey)
        .cornerRadius(16)
    }
    
    private func getChartData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        // Filter assessments based on time period
        let filteredResults = assessmentResultsHistory.filter { result in
            guard let assessment = assessmentHistory.first(where: { $0.assessmentId == result.assessmentId }) else {
                return false
            }
            
            let daysSinceAssessment = calendar.dateComponents([.day], from: assessment.createdAt, to: now).day ?? 0
            
            switch selectedTimePeriod {
            case .week:
                return daysSinceAssessment <= 7
            case .month:
                return daysSinceAssessment <= 30
            case .quarter:
                return daysSinceAssessment <= 90
            case .year:
                return daysSinceAssessment <= 365
            }
        }
        
        // Convert to chart data points
        return filteredResults.enumerated().map { index, result in
            ChartDataPoint(
                x: Double(index),
                y: result.durabilityScore * 100, // Convert to percentage
                date: assessmentHistory.first(where: { $0.assessmentId == result.assessmentId })?.createdAt ?? Date(),
                label: "Assessment \(index + 1)"
            )
        }.sorted { $0.date < $1.date }
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

// MARK: - Supporting Types

enum TimePeriod: CaseIterable {
    case week, month, quarter, year
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "Quarter"
        case .year: return "Year"
        }
    }
}

// MARK: - Line Chart View
struct LineChartView: View {
    let data: [ChartDataPoint]
    let selectedTimePeriod: TimePeriod
    
    var body: some View {
        GeometryReader { geometry in
            if data.count < 2 {
                // Show placeholder for insufficient data
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Text("Need at least 2 assessments to show trend")
                            .foregroundColor(.secondaryText)
                            .font(.caption)
                    )
            } else {
                // Draw the line chart
                ZStack {
                    // Background grid
                    ChartGrid(data: data, geometry: geometry)
                    
                    // Line path
                    ChartLine(data: data, geometry: geometry)
                    
                    // Data points
                    ChartPoints(data: data, geometry: geometry)
                }
            }
        }
    }
}

struct ChartGrid: View {
    let data: [ChartDataPoint]
    let geometry: GeometryProxy
    
    var body: some View {
        let maxY = data.map { $0.y }.max() ?? 100
        let minY = data.map { $0.y }.min() ?? 0
        
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
                .frame(width: 30)
                
                Spacer()
            }
        )
    }
}

struct ChartLine: View {
    let data: [ChartDataPoint]
    let geometry: GeometryProxy
    
    var body: some View {
        let maxY = data.map { $0.y }.max() ?? 100
        let minY = data.map { $0.y }.min() ?? 0
        let maxX = Double(data.count - 1)
        
        Path { path in
            for (index, point) in data.enumerated() {
                let x = (point.x / maxX) * geometry.size.width
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

struct ChartPoints: View {
    let data: [ChartDataPoint]
    let geometry: GeometryProxy
    
    var body: some View {
        let maxY = data.map { $0.y }.max() ?? 100
        let minY = data.map { $0.y }.min() ?? 0
        let maxX = Double(data.count - 1)
        
        ForEach(data) { point in
            let x = (point.x / maxX) * geometry.size.width
            let y = geometry.size.height - ((point.y - minY) / (maxY - minY)) * geometry.size.height
            
            Circle()
                .fill(Color.electricGreen)
                .frame(width: 6, height: 6)
                .position(x: x, y: y)
        }
    }
}

#Preview {
    ProgressDashboardView()
        .environmentObject(AppState())
}

