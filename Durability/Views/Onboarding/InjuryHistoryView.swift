import SwiftUI

struct InjuryHistoryView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var appState: AppState
     @State private var injuries: [Injury] = []
     
     var body: some View {
         ScrollView {
             VStack(alignment: .leading, spacing: 20) {
                 Text("Do you have any prior or existing injuries?")
                     .font(.title)
                     .fontWeight(.bold)
                 
                 Toggle("I have injuries", isOn: $viewModel.hasInjuries)
                     .font(.headline)
                 
                 if viewModel.hasInjuries {
                     Text("Select all that apply")
                         .font(.subheadline)
                         .foregroundColor(.secondary)
                     
                     LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                         ForEach(injuries) { injury in
                             InjuryCard(
                                 injury: injury,
                                 isSelected: viewModel.selectedInjuries.contains(injury.id)
                             ) {
                                 if viewModel.selectedInjuries.contains(injury.id) {
                                     viewModel.selectedInjuries.remove(injury.id)
                                 } else {
                                     viewModel.selectedInjuries.insert(injury.id)
                                 }
                             }
                         }
                     }
                     
                     VStack(alignment: .leading, spacing: 10) {
                         Text("Other injuries")
                             .font(.headline)
                         
                         TextField("Describe other injuries", text: $viewModel.otherInjuryText, axis: .vertical)
                             .textFieldStyle(RoundedBorderTextFieldStyle())
                             .lineLimit(3...6)
                             .onChange(of: viewModel.otherInjuryText) { _, _ in
                                 // Data will be saved when user presses Next
                             }
                     }
                     
                     Text("Note: Always follow medical advice from licensed professionals")
                         .font(.caption)
                         .foregroundColor(.secondary)
                         .padding(.top)
                 }
                 
                 Spacer()
             }
             .padding()
         }
                 .onAppear {
            loadInjuries()
            // Load existing user selections from database
            Task {
                await viewModel.loadExistingSelectionsForCurrentStep()
            }
        }
     }
     
     private func loadInjuries() {
         Task {
             do {
                 let dbInjuries = try await appState.profileService.getInjuries()
                 if !dbInjuries.isEmpty {
                     self.injuries = dbInjuries
                 } else {
                     self.injuries = defaultInjuries()
                 }
             } catch {
                 print("Error loading injuries: \(error)")
                 self.injuries = defaultInjuries()
             }
         }
     }
     
     private func defaultInjuries() -> [Injury] {
         return [
             Injury(id: 1, name: "IT Band"),
             Injury(id: 2, name: "Shin Splints"),
             Injury(id: 3, name: "Rotator Cuff"),
             Injury(id: 4, name: "ACL"),
             Injury(id: 5, name: "MCL"),
             Injury(id: 6, name: "PCL"),
             Injury(id: 7, name: "Achilles"),
             Injury(id: 8, name: "UCL"),
             Injury(id: 9, name: "Shoulder Labral Tear"),
             Injury(id: 10, name: "Hip Labral Tear")
         ]
     }
 }
 
 struct InjuryCard: View {
     let injury: Injury
     let isSelected: Bool
     let onTap: () -> Void
     
     var body: some View {
         Button(action: onTap) {
             VStack {
                 Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                     .font(.title2)
                     .foregroundColor(isSelected ? .accentColor : .secondary)
                 
                 Text(injury.name)
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
     InjuryHistoryView(viewModel: OnboardingViewModel())
        .environmentObject(AppState())
 }
