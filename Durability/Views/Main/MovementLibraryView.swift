import SwiftUI
import Foundation

struct MovementLibraryView: View {
    @StateObject private var viewModel = MovementLibraryViewModel()

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search movements", text: $viewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()

                // Filter Row (placeholder)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(filterOptions, id: \.self) { filter in
                            FilterChip(label: filter, isSelected: viewModel.selectedFilters.contains(filter)) {
                                toggleFilter(filter)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }

                // Movement Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.filteredMovements, id: \.id) { movement in
                            NavigationLink(destination: MovementDetailView(movement: movement)) {
                                MovementCardView(movement: movement)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Movement Library")
            .task {
                await viewModel.fetch()
            }
        }
    }

    var filterOptions: [String] {
        ["Sport", "Equipment", "Mobility", "Strength"]
    }

    func toggleFilter(_ filter: String) {
        if let index = viewModel.selectedFilters.firstIndex(of: filter) {
            viewModel.selectedFilters.remove(at: index)
        } else {
            viewModel.selectedFilters.append(filter)
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct MovementCardView: View {
    let movement: Movement

    var body: some View {
        VStack {
            Text(movement.name)
                .font(.headline)
                .padding()
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

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
                }

                // Tags horizontal scroller
                if hasAnyTags {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                tagChips(from: movement.jointsImpacted, color: .blue)
                                tagChips(from: movement.musclesImpacted, color: .purple)
                                tagChips(from: movement.superMetricsImpacted, color: .orange)
                                tagChips(from: movement.sportsImpacted, color: .green)
                            }
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
        !(movement.jointsImpacted.isEmpty && movement.musclesImpacted.isEmpty && movement.superMetricsImpacted.isEmpty && movement.sportsImpacted.isEmpty)
    }

    @ViewBuilder
    private func tagChips(from items: [String], color: Color) -> some View {
        ForEach(items, id: \.self) { tag in
            Text(tag)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(color.opacity(0.15))
                .foregroundColor(color)
                .cornerRadius(12)
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
            Spacer()
            Text(String(format: "%.0f%%", score * 100))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(tint)
            ProgressView(value: min(max(score, 0), 1))
                .progressViewStyle(LinearProgressViewStyle(tint: tint))
                .frame(width: 140)
        }
    }
}

@MainActor
private class MovementDetailViewModel: ObservableObject {
    @Published var longDescription: String?
    private let service = MovementLibraryService()

    func loadLongDescription(name: String) async {
        do {
            self.longDescription = try await service.getMovementLongDescription(byName: name)
        } catch {
            self.longDescription = nil
        }
    }
}

#Preview {
    MovementLibraryView()
}
