import SwiftUI

struct MovementDetailView: View {
    let movement: Movement
    @StateObject private var vm = MovementDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text(movement.name)
                    .font(.largeTitle)
                    .bold()

                // Video placeholder
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 200)
                        .cornerRadius(12)
                    VStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Video coming soon")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }

                // Long description (from movement_content)
                if let longText = vm.longDescription, !longText.isEmpty {
                    Text(longText)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                } else if !movement.description.isEmpty {
                    Text(movement.description)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                } else if vm.longDescription == nil {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading description...")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("No description available for this movement.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                }

                // Tags organized by category
                if hasAnyTags {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Movement Details")
                            .font(.headline)
                        
                        if !movement.jointsImpacted.isEmpty {
                            tagSection(title: "Joints Impacted", tags: movement.jointsImpacted, color: .blue)
                        }
                        
                        if !movement.musclesImpacted.isEmpty {
                            tagSection(title: "Muscles Impacted", tags: movement.musclesImpacted, color: .purple)
                        }
                        
                        if !movement.superMetricsImpacted.isEmpty {
                            tagSection(title: "Super Metrics", tags: movement.superMetricsImpacted, color: .orange)
                        }
                        
                        if !movement.sportsImpacted.isEmpty {
                            tagSection(title: "Sports", tags: movement.sportsImpacted, color: .green)
                        }
                        
                        if !movement.intensityOptions.isEmpty {
                            tagSection(title: "Intensity Options", tags: movement.intensityOptions, color: .red)
                        }
                    }
                }

                // Module score breakdown
                VStack(alignment: .leading, spacing: 8) {
                    Text("Module Scores")
                        .font(.headline)
                    ModuleScoreRow(label: "Recovery", score: movement.recoveryImpactScore, tint: .blue)
                    ModuleScoreRow(label: "Resilience", score: movement.resilienceImpactScore, tint: .purple)
                    ModuleScoreRow(label: "Results", score: movement.resultsImpactScore, tint: .green)
                }
            }
            .padding()
        }
        .navigationTitle(movement.name)
        .task { await vm.loadLongDescription(name: movement.name) }
    }

    private var hasAnyTags: Bool {
        !(movement.jointsImpacted.isEmpty && movement.musclesImpacted.isEmpty && movement.superMetricsImpacted.isEmpty && movement.sportsImpacted.isEmpty && movement.intensityOptions.isEmpty)
    }

    @ViewBuilder
    private func tagSection(title: String, tags: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.15))
                        .foregroundColor(color)
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
}

private struct ModuleScoreRow: View {
    let label: String
    let score: Double
    let tint: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(String(format: "%.0f%%", score * 100))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(tint)
                
                ProgressView(value: min(max(score, 0), 1))
                    .progressViewStyle(LinearProgressViewStyle(tint: tint))
                    .frame(width: 140)
            }
        }
        .padding(.vertical, 4)
    }
}

@MainActor
private class MovementDetailViewModel: ObservableObject {
    @Published var longDescription: String?
    private let service = MovementLibraryService()
    
    func loadLongDescription(name: String) async {
        do {
            let description = try await service.getMovementLongDescription(byName: name)
            self.longDescription = description
        } catch {
            self.longDescription = nil
        }
    }
}

#Preview {
    NavigationStack {
        MovementDetailView(movement: Movement(
            id: 1,
            name: "Sample Movement",
            description: "A sample movement for testing",
            videoURL: nil,
            jointsImpacted: ["Knee", "Hip"],
            musclesImpacted: ["Quadriceps", "Glutes"],
            superMetricsImpacted: ["Strength", "Power"],
            sportsImpacted: ["Basketball", "Soccer"],
            intensityOptions: ["Light", "Medium", "Heavy"],
            recoveryImpactScore: 0.7,
            resilienceImpactScore: 0.8,
            resultsImpactScore: 0.6
        ))
    }
}
