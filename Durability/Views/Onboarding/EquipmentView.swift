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
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                        ForEach(equipment) { item in
                            EquipmentCard(
                                equipment: item,
                                isSelected: viewModel.selectedEquipment.contains(item.id)
                            ) {
                                if viewModel.selectedEquipment.contains(item.id) {
                                    viewModel.selectedEquipment.remove(item.id)
                                } else {
                                    viewModel.selectedEquipment.insert(item.id)
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
        }
    }
    
    private func loadEquipment() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Try to load from database first
                let dbEquipment = try await appState.profileService.getEquipment()
                if !dbEquipment.isEmpty {
                    self.equipment = dbEquipment
                } else {
                    // Fall back to default equipment if database is empty
                    self.equipment = getDefaultEquipment()
                }
            } catch {
                // If database fails, use default equipment
                print("Error loading equipment from database: \(error)")
                self.equipment = getDefaultEquipment()
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func getDefaultEquipment() -> [Equipment] {
        return [
            Equipment(id: 1, name: "Foam Roller"),
            Equipment(id: 2, name: "Dumbbells"),
            Equipment(id: 3, name: "Stretch Band"),
            Equipment(id: 4, name: "Medicine Ball"),
            Equipment(id: 5, name: "Squat Rack"),
            Equipment(id: 6, name: "Bench Press"),
            Equipment(id: 7, name: "Pull-up Bar"),
            Equipment(id: 8, name: "Resistance Bands"),
            Equipment(id: 9, name: "Yoga Mat"),
            Equipment(id: 10, name: "Kettlebell"),
            Equipment(id: 11, name: "Treadmill"),
            Equipment(id: 12, name: "None")
        ]
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
