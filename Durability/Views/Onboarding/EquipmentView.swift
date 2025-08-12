import SwiftUI

struct EquipmentView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var appState: AppState
    @State private var equipment: [Equipment] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("What equipment do you have access to?")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Select all that apply")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if isLoading {
                    ProgressView("Loading equipment...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                } else if !equipment.isEmpty {
                    // Show "None" option prominently at the top
                    if let noneEquipment = equipment.first(where: { $0.name.lowercased() == "none" }) {
                        EquipmentCard(
                            equipment: noneEquipment,
                            isSelected: viewModel.selectedEquipment.contains(noneEquipment.id)
                        ) {
                            if viewModel.selectedEquipment.contains(noneEquipment.id) {
                                viewModel.selectedEquipment.remove(noneEquipment.id)
                            } else {
                                // If selecting "None", clear all other selections
                                viewModel.selectedEquipment.removeAll()
                                viewModel.selectedEquipment.insert(noneEquipment.id)
                            }
                        }
                        .padding(.bottom, 10)
                    }
                    
                    // Show other equipment options
                    let otherEquipment = equipment.filter { $0.name.lowercased() != "none" }
                    if !otherEquipment.isEmpty {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                            ForEach(otherEquipment) { item in
                                EquipmentCard(
                                    equipment: item,
                                    isSelected: viewModel.selectedEquipment.contains(item.id)
                                ) {
                                    // If selecting other equipment, remove "None" selection
                                    if let noneEquipment = equipment.first(where: { $0.name.lowercased() == "none" }) {
                                        viewModel.selectedEquipment.remove(noneEquipment.id)
                                    }
                                    
                                    if viewModel.selectedEquipment.contains(item.id) {
                                        viewModel.selectedEquipment.remove(item.id)
                                    } else {
                                        viewModel.selectedEquipment.insert(item.id)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Text("No equipment options available")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            loadEquipment()
            // Load existing user selections from database
            Task {
                await viewModel.loadExistingSelectionsForCurrentStep()
            }
        }
    }
    
    private func loadEquipment() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Always load from database - this is the source of truth
                let dbEquipment = try await appState.profileService.getEquipment()
                self.equipment = dbEquipment
            } catch {
                // If database fails, show error
                print("Error loading equipment from database: \(error)")
                self.errorMessage = "Failed to load equipment options"
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct EquipmentCard: View {
    let equipment: Equipment
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                Text(equipment.name)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    EquipmentView(viewModel: OnboardingViewModel())
        .environmentObject(AppState())
}
