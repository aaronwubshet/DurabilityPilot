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
                    // Show all equipment options in a grid, with "None" positioned correctly
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                        ForEach(equipment) { item in
                            EquipmentCard(
                                equipment: item,
                                isSelected: viewModel.selectedEquipment.contains(item.id)
                            ) {
                                print("EquipmentView: Equipment card tapped - \(item.name) (ID: \(item.id))")
                                print("EquipmentView: Current selections before: \(viewModel.selectedEquipment)")
                                
                                if item.name.lowercased() == "none" {
                                    // Handle "None" selection
                                    if viewModel.selectedEquipment.contains(item.id) {
                                        viewModel.selectedEquipment.remove(item.id)
                                        print("EquipmentView: Removed 'None' selection")
                                    } else {
                                        // If selecting "None", clear all other selections
                                        viewModel.selectedEquipment.removeAll()
                                        viewModel.selectedEquipment.insert(item.id)
                                        print("EquipmentView: Selected 'None', cleared all other selections")
                                    }
                                } else {
                                    // Handle other equipment selection
                                    // If selecting other equipment, remove "None" selection
                                    if let noneEquipment = equipment.first(where: { $0.name.lowercased() == "none" }) {
                                        viewModel.selectedEquipment.remove(noneEquipment.id)
                                        print("EquipmentView: Removed 'None' selection when selecting other equipment")
                                    }
                                    
                                    if viewModel.selectedEquipment.contains(item.id) {
                                        viewModel.selectedEquipment.remove(item.id)
                                        print("EquipmentView: Removed equipment selection: \(item.name)")
                                    } else {
                                        viewModel.selectedEquipment.insert(item.id)
                                        print("EquipmentView: Added equipment selection: \(item.name)")
                                    }
                                }
                                
                                print("EquipmentView: Current selections after: \(viewModel.selectedEquipment)")
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
        .autoDismissKeyboard()
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
