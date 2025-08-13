import SwiftUI

struct SuperMetricsRadarChartView: View {
    var results: AssessmentResult?
    var history: [Assessment]?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Super Metrics")
                .font(.title2)
                .fontWeight(.semibold)

            if let results = results {
                SimpleMetricsChart(
                    data: [
                        results.rangeOfMotionScore,
                        results.flexibilityScore,
                        results.functionalStrengthScore,
                        results.mobilityScore,
                        results.aerobicCapacityScore
                    ],
                    labels: ["ROM", "Flex", "Strength", "Mobility", "Aerobic"]
                )
                .frame(height: 250)
            } else {
                Text("No data available.")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
}

// A very simple metrics chart using bars instead of radar
struct SimpleMetricsChart: View {
    var data: [Double]
    var labels: [String]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(zip(data, labels).enumerated()), id: \.offset) { index, item in
                HStack {
                    Text(item.1)
                        .font(.caption)
                        .frame(width: 60, alignment: .leading)
                    
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(width: geometry.size.width * item.0)
                    }
                    .frame(height: 20)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                    
                    Text("\(Int(item.0 * 100))%")
                        .font(.caption)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .padding()
    }
}

#Preview {
    SuperMetricsRadarChartView(
        results: AssessmentResult(
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

