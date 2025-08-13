import SwiftUI

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @EnvironmentObject var appState: AppState
    @State private var selectedMetric: AnalyticsMetric = .durabilityScore
    @State private var showingExportSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkSpaceGrey
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Progress indicator
                        ProgressIndicatorView(progress: 0.7)
                        
                        // Super Metrics Overview
                        SuperMetricsOverviewCard(results: viewModel.latestAssessmentResult)
                        
                        // Progress Trends
                        ProgressTrendsCard(
                            selectedMetric: $selectedMetric,
                            chartData: viewModel.getChartData(for: selectedMetric)
                        )
                        
                        // Insights
                        InsightsCard(insights: viewModel.insights)
                        
                        // Recommendations
                        RecommendationsCard(recommendations: viewModel.recommendations)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Export") {
                        showingExportSheet = true
                    }
                    .foregroundColor(.electricGreen)
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
            }
            .onAppear {
                viewModel.loadAnalyticsData(appState: appState)
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportView()
            }
        }
    }
}

// MARK: - Progress Indicator
struct ProgressIndicatorView: View {
    let progress: Double
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < Int(progress * 8) ? Color.electricGreen : Color.gray.opacity(0.3))
                    .frame(width: 4, height: 8)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Super Metrics Overview Card
struct SuperMetricsOverviewCard: View {
    let results: AssessmentResult?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Super Metrics Overview")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.lightText)
            
            if let results = results {
                HStack(spacing: 12) {
                    MetricCircleView(name: "ROM", score: results.rangeOfMotionScore, color: .electricGreen)
                    MetricCircleView(name: "Flex", score: results.flexibilityScore, color: .electricGreen)
                    MetricCircleView(name: "Mob", score: results.mobilityScore, color: .electricGreen)
                    MetricCircleView(name: "Strength", score: results.functionalStrengthScore, color: .orange)
                    MetricCircleView(name: "Aerobic", score: results.aerobicCapacityScore, color: .red)
                }
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

struct MetricCircleView: View {
    let name: String
    let score: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: score)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(score * 100))")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.lightText)
            }
            
            Text(name)
                .font(.caption2)
                .foregroundColor(.secondaryText)
        }
    }
}

// MARK: - Progress Trends Card
struct ProgressTrendsCard: View {
    @Binding var selectedMetric: AnalyticsMetric
    let chartData: [ChartDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress Trends")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.lightText)
            
            // Metric selector
            HStack(spacing: 8) {
                ForEach(AnalyticsMetric.allCases, id: \.self) { metric in
                    Button(metric.displayName) {
                        selectedMetric = metric
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedMetric == metric ? Color.electricGreen : Color.clear)
                    .foregroundColor(selectedMetric == metric ? .darkSpaceGrey : .secondaryText)
                    .cornerRadius(8)
                }
            }
            
            // Line Chart
            if chartData.isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 120)
                    .overlay(
                        Text("No trend data available")
                            .foregroundColor(.secondaryText)
                    )
            } else {
                AnalyticsLineChartView(data: chartData)
                    .frame(height: 120)
            }
        }
        .padding(20)
        .background(Color.lightSpaceGrey)
        .cornerRadius(16)
    }
}

// MARK: - Analytics Line Chart
struct AnalyticsLineChartView: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        GeometryReader { geometry in
            if data.count < 2 {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Text("Need at least 2 data points")
                            .foregroundColor(.secondaryText)
                            .font(.caption)
                    )
            } else {
                ZStack {
                    // Background grid
                    AnalyticsChartGrid(data: data, geometry: geometry)
                    
                    // Line path
                    AnalyticsChartLine(data: data, geometry: geometry)
                    
                    // Data points
                    AnalyticsChartPoints(data: data, geometry: geometry)
                }
            }
        }
    }
}

struct AnalyticsChartGrid: View {
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

struct AnalyticsChartLine: View {
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

struct AnalyticsChartPoints: View {
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

// MARK: - Insights Card
struct InsightsCard: View {
    let insights: [Insight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.lightText)
            
            if insights.isEmpty {
                Text("No insights available yet")
                    .foregroundColor(.secondaryText)
            } else {
                VStack(spacing: 12) {
                    ForEach(insights) { insight in
                        AnalyticsInsightRow(insight: insight)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.lightSpaceGrey)
        .cornerRadius(16)
    }
}

struct AnalyticsInsightRow: View {
    let insight: Insight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.iconName)
                .foregroundColor(insight.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.lightText)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
    }
}

// MARK: - Recommendations Card
struct RecommendationsCard: View {
    let recommendations: [Recommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.lightText)
            
            if recommendations.isEmpty {
                Text("No recommendations available yet")
                    .foregroundColor(.secondaryText)
            } else {
                VStack(spacing: 12) {
                    ForEach(recommendations) { recommendation in
                        RecommendationRow(recommendation: recommendation)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.lightSpaceGrey)
        .cornerRadius(16)
    }
}

struct RecommendationRow: View {
    let recommendation: Recommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: recommendation.iconName)
                    .foregroundColor(recommendation.color)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.lightText)
                    
                    Text(recommendation.description)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Severity badge
                Text(recommendation.severity.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(recommendation.severity.color)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Export View
struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 60))
                    .foregroundColor(.electricGreen)
                
                Text("Export Analytics")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.lightText)
                
                Text("Export your progress data and analytics for external analysis")
                    .font(.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                
                // Export options would go here
                Text("Export functionality coming soon...")
                    .foregroundColor(.secondaryText)
                    .font(.caption)
                
                Spacer()
            }
            .padding(40)
            .background(Color.darkSpaceGrey)
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.electricGreen)
                }
            }
        }
    }
}

// MARK: - Supporting Types
enum AnalyticsMetric: CaseIterable {
    case durabilityScore, rangeOfMotion, flexibility, mobility, functionalStrength, aerobicCapacity
    
    var displayName: String {
        switch self {
        case .durabilityScore: return "Score"
        case .rangeOfMotion: return "Range of Motion"
        case .flexibility: return "Flexibility"
        case .mobility: return "Mobility"
        case .functionalStrength: return "Strength"
        case .aerobicCapacity: return "Aerobic"
        }
    }
}

struct Insight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let color: Color
}

struct Recommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let color: Color
    let severity: RecommendationSeverity
}

enum RecommendationSeverity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(AppState())
}
