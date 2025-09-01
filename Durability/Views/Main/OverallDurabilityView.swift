import SwiftUI

struct OverallDurabilityView: View {
    let score: Double

    var body: some View {
        VStack(spacing: 12) {
            Text("Overall Durability")
                .font(.title2)
                .fontWeight(.semibold)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 15)

                Circle()
                    .trim(from: 0, to: score)
                    .stroke(scoreColor(score), style: StrokeStyle(lineWidth: 15, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.0), value: score)

                VStack {
                    Text("\(Int(score * 100))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 150, height: 150)
            
            Text(scoreCategory(score))
                .font(.headline)
                .foregroundColor(scoreColor(score))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0.75...: return .green    // 75-100: Green
        case 0.5..<0.75: return .yellow   // 50-75: Yellow
        case 0.25..<0.5: return .orange   // 25-50: Orange
        default: return .red              // 0-25: Red
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

#Preview {
    OverallDurabilityView(score: 0.85)
}

