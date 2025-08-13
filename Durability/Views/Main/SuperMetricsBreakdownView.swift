import SwiftUI

struct SuperMetricsBreakdownView: View {
    let result: AssessmentResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metrics Breakdown")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 16) {
                MetricBarView(name: "Range of Motion", score: result.rangeOfMotionScore)
                MetricBarView(name: "Flexibility", score: result.flexibilityScore)
                MetricBarView(name: "Functional Strength", score: result.functionalStrengthScore)
                MetricBarView(name: "Mobility", score: result.mobilityScore)
                MetricBarView(name: "Aerobic Capacity", score: result.aerobicCapacityScore)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
}

struct MetricBarView: View {
    let name: String
    let score: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.caption)
                Spacer()
                Text("\(Int(score * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor(score))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .frame(width: geometry.size.width, height: 8)
                        .foregroundColor(Color.gray.opacity(0.2))

                    LinearGradient(gradient: Gradient(colors: [.red, .orange, .yellow, .green]), startPoint: .leading, endPoint: .trailing)
                        .mask(
                            Capsule()
                                .frame(width: geometry.size.width * CGFloat(score), height: 8)
                        )
                        .animation(.easeOut(duration: 1.0), value: score)
                }
            }
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

#Preview {
    SuperMetricsBreakdownView(
        result: AssessmentResult(
            id: 1,
            assessmentId: 1, 
            profileId: "test-profile-id",
            bodyArea: "Overall", 
            durabilityScore: 0.75,
            rangeOfMotionScore: 0.8, 
            flexibilityScore: 0.6, 
            functionalStrengthScore: 0.9,
            mobilityScore: 0.7, 
            aerobicCapacityScore: 0.85
        )
    )
}

