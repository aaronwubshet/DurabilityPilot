import SwiftUI
import Foundation

struct SuperMetricsRadarChartView: View {
    var results: AssessmentResult?
    var history: [Assessment]?

    var body: some View {
        VStack(spacing: 20) {
            if let results = results {
                // Radar Chart
                RadarChartView(
                    data: [
                        results.rangeOfMotionScore,
                        results.flexibilityScore,
                        results.functionalStrengthScore,
                        results.mobilityScore,
                        results.aerobicCapacityScore
                    ],
                    labels: ["Range of Motion", "Flexibility", "Mobility", "Functional Strength", "Aerobic Capacity"]
                )
                .frame(height: 200)
                
                // Metrics List
                MetricsListView(results: results)
            } else {
                Text("No metrics data available")
                    .foregroundColor(.secondaryText)
            }
        }
    }
}

// MARK: - Radar Chart Implementation
struct RadarChartView: View {
    let data: [Double]
    let labels: [String]
    
    private let numberOfPoints = 5
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let chartRadius = min(geometry.size.width, geometry.size.height) / 2 - 20
            
            ZStack {
                // Background circles
                BackgroundCircles(chartRadius: chartRadius)
                
                // Radar lines (spokes)
                RadarLines(numberOfPoints: numberOfPoints, center: center, chartRadius: chartRadius)
                
                // Data polygon with gradient fill
                if data.count == numberOfPoints {
                    RadarPolygon(data: data, center: center, radius: chartRadius)
                        .fill(
                            LinearGradient(
                                colors: [.red, .orange, .yellow, .green],
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing
                            )
                            .opacity(0.3)
                        )
                        .overlay(
                            RadarPolygon(data: data, center: center, radius: chartRadius)
                                .stroke(
                                    LinearGradient(
                                        colors: [.red, .orange, .yellow, .green],
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                                )
                        )
                }
                
                // Data points
                DataPoints(data: data, numberOfPoints: numberOfPoints, center: center, chartRadius: chartRadius)
            }
        }
    }
}

struct BackgroundCircles: View {
    let chartRadius: CGFloat
    
    var body: some View {
        ForEach(0..<5, id: \.self) { level in
            let circleRadius = chartRadius * CGFloat(level + 1) / 5
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                .frame(width: circleRadius * 2, height: circleRadius * 2)
        }
    }
}

struct RadarLines: View {
    let numberOfPoints: Int
    let center: CGPoint
    let chartRadius: CGFloat
    
    var body: some View {
        ForEach(0..<numberOfPoints, id: \.self) { index in
            RadarLine(
                index: index,
                numberOfPoints: numberOfPoints,
                center: center,
                chartRadius: chartRadius
            )
        }
    }
}

struct RadarLine: View {
    let index: Int
    let numberOfPoints: Int
    let center: CGPoint
    let chartRadius: CGFloat
    
    var body: some View {
        let endPoint = calculateEndPoint()
        
        Path { path in
            path.move(to: center)
            path.addLine(to: endPoint)
        }
        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
    }
    
    private func calculateEndPoint() -> CGPoint {
        let angle = CGFloat((2 * .pi * Double(index)) / Double(numberOfPoints) - .pi / 2)
        return CGPoint(
            x: center.x + cos(Double(angle)) * chartRadius,
            y: center.y + sin(Double(angle)) * chartRadius
        )
    }
}

struct DataPoints: View {
    let data: [Double]
    let numberOfPoints: Int
    let center: CGPoint
    let chartRadius: CGFloat
    
    var body: some View {
        ForEach(0..<min(data.count, numberOfPoints), id: \.self) { index in
            DataPoint(
                index: index,
                value: data[index],
                numberOfPoints: numberOfPoints,
                center: center,
                chartRadius: chartRadius
            )
        }
    }
}

struct DataPoint: View {
    let index: Int
    let value: Double
    let numberOfPoints: Int
    let center: CGPoint
    let chartRadius: CGFloat
    
    var body: some View {
        let pointPosition = calculatePointPosition()
        
        Circle()
            .fill(scoreColor(value))
            .frame(width: 6, height: 6)
            .position(pointPosition)
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0.75...: return .green    // 75-100: Green
        case 0.5..<0.75: return .yellow   // 50-75: Yellow
        case 0.25..<0.5: return .orange   // 25-50: Orange
        default: return .red              // 0-25: Red
        }
    }
    
    private func calculatePointPosition() -> CGPoint {
        let angle = CGFloat((2 * .pi * Double(index)) / Double(numberOfPoints) - .pi / 2)
        let pointRadius = chartRadius * value
        return CGPoint(
            x: center.x + cos(Double(angle)) * pointRadius,
            y: center.y + sin(Double(angle)) * pointRadius
        )
    }
}

struct RadarPolygon: Shape {
    let data: [Double]
    let center: CGPoint
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let numberOfPoints = data.count
        
        guard numberOfPoints > 0 else { return path }
        
        for (index, value) in data.enumerated() {
            let point = calculatePoint(index: index, value: value, numberOfPoints: numberOfPoints)
            
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.closeSubpath()
        return path
    }
    
    private func calculatePoint(index: Int, value: Double, numberOfPoints: Int) -> CGPoint {
        let angle = CGFloat((2 * .pi * Double(index)) / Double(numberOfPoints) - .pi / 2)
        let pointRadius = radius * value
        return CGPoint(
            x: center.x + cos(Double(angle)) * pointRadius,
            y: center.y + sin(Double(angle)) * pointRadius
        )
    }
}

// MARK: - Metrics List View
struct MetricsListView: View {
    let results: AssessmentResult
    
    var body: some View {
        VStack(spacing: 8) {
            RadarMetricRow(name: "Range of Motion", score: results.rangeOfMotionScore)
            RadarMetricRow(name: "Flexibility", score: results.flexibilityScore)
            RadarMetricRow(name: "Mobility", score: results.mobilityScore)
            RadarMetricRow(name: "Functional Strength", score: results.functionalStrengthScore)
            RadarMetricRow(name: "Aerobic Capacity", score: results.aerobicCapacityScore)
        }
    }
}

struct RadarMetricRow: View {
    let name: String
    let score: Double
    
    var body: some View {
        HStack {
            Circle()
                .fill(scoreColor(score))
                .frame(width: 8, height: 8)
            
            Text(name)
                .font(.caption)
                .foregroundColor(.lightText)
            
            Spacer()
            
            Text("\(Int(score * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(scoreColor(score))
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0.75...: return .green    // 75-100: Green
        case 0.5..<0.75: return .yellow   // 50-75: Yellow
        case 0.25..<0.5: return .orange   // 25-50: Orange
        default: return .red              // 0-25: Red
        }
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
            rangeOfMotionScore: 0.78, 
            flexibilityScore: 0.72, 
            functionalStrengthScore: 0.82,
            mobilityScore: 0.75, 
            aerobicCapacityScore: 0.68
        )
    )
    .padding()
    .background(Color.darkSpaceGrey)
}

