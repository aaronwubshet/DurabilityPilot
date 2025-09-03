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

#Preview {
    MovementLibraryView()
}
