import SwiftUI

struct AssessmentResultsView: View {
    @ObservedObject var viewModel: AssessmentViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Assessment Results")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Your movement assessment has been analyzed. Here are your scores:")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                // Overall durability score
                if let overallResult = viewModel.assessmentResults.first(where: { $0.bodyArea == "Overall" }) {
                    VStack(spacing: 10) {
                        Text("Overall Durability Score")
                            .font(.headline)
                        
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .trim(from: 0, to: overallResult.durabilityScore)
                                .stroke(scoreColor(overallResult.durabilityScore), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                            
                            VStack {
                                Text("\(Int(overallResult.durabilityScore * 100))")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text("%")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                }
                
                // Super metrics breakdown
                VStack(alignment: .leading, spacing: 15) {
                    Text("Super Metrics Breakdown")
                        .font(.headline)
                    
                    if let overallResult = viewModel.assessmentResults.first(where: { $0.bodyArea == "Overall" }) {
                        VStack(spacing: 10) {
                            MetricRow(name: "Range of Motion", score: overallResult.rangeOfMotionScore)
                            MetricRow(name: "Flexibility", score: overallResult.flexibilityScore)
                            MetricRow(name: "Mobility", score: overallResult.mobilityScore)
                            MetricRow(name: "Functional Strength", score: overallResult.functionalStrengthScore)
                            MetricRow(name: "Aerobic Capacity", score: overallResult.aerobicCapacityScore)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                
                // Body area scores
                VStack(alignment: .leading, spacing: 15) {
                    Text("Body Area Scores")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                        ForEach(viewModel.assessmentResults.filter { $0.bodyArea != "Overall" }) { result in
                            BodyAreaCard(result: result)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                
                Button(action: {
                    viewModel.completeAssessment()
                    appState.assessmentCompleted = true
                }) {
                    Text("Generate My Plan")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0.8...: return .green
        case 0.6..<0.8: return .yellow
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

struct MetricRow: View {
    let name: String
    let score: Double
    
    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(Int(score * 100))%")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(scoreColor(score))
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0.8...: return .green
        case 0.6..<0.8: return .yellow
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

struct BodyAreaCard: View {
    let result: AssessmentResult
    
    var body: some View {
        VStack(spacing: 8) {
            Text(result.bodyArea)
                .font(.caption)
                .fontWeight(.semibold)
            
            Text("\(Int(result.durabilityScore * 100))%")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(scoreColor(result.durabilityScore))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0.8...: return .green
        case 0.6..<0.8: return .yellow
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

#Preview {
    AssessmentResultsView(viewModel: AssessmentViewModel())
        .environmentObject(AppState())
}
