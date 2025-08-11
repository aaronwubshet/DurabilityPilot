import SwiftUI

struct GoalsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var appState: AppState
     @State private var goals: [Goal] = []
     private let defaultGoals: [String] = [
         "Compete in an upcoming race/match",
         "Increase my fitness (strength, endurance, aerobic)",
         "Recover from my injury",
         "Avoid future injury / re-injury"
     ]
     
     var body: some View {
         ScrollView {
             VStack(alignment: .leading, spacing: 20) {
                 Text("What are your goals?")
                     .font(.title)
                     .fontWeight(.bold)
                 
                 Text("Select all that apply")
                     .font(.subheadline)
                     .foregroundColor(.secondary)
                 
                 LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 15) {
                     ForEach(goals) { goal in
                         GoalCard(
                             goal: goal,
                             isSelected: viewModel.selectedGoals.contains(goal.id)
                         ) {
                             if viewModel.selectedGoals.contains(goal.id) {
                                 viewModel.selectedGoals.remove(goal.id)
                             } else {
                                 viewModel.selectedGoals.insert(goal.id)
                             }
                         }
                     }
                 }
                 
                 Spacer()
             }
             .padding()
         }
         .onAppear {
             loadGoals()
         }
     }
     
     private func loadGoals() {
         Task {
             do {
                  let fetched = try await appState.profileService.getGoals()
                  if fetched.isEmpty {
                      // Fallback defaults
                      self.goals = defaultGoals.enumerated().map { idx, name in
                          Goal(id: idx + 1, name: name)
                      }
                  } else {
                      self.goals = fetched
                  }
             } catch {
                  // Fallback defaults on error
                  self.goals = defaultGoals.enumerated().map { idx, name in
                      Goal(id: idx + 1, name: name)
                  }
             }
         }
     }
 }

 struct GoalCard: View {
     let goal: Goal
     let isSelected: Bool
     let onTap: () -> Void
     
     var body: some View {
         Button(action: onTap) {
             HStack {
                 Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                     .font(.title2)
                     .foregroundColor(isSelected ? .accentColor : .secondary)
                 
                 Text(goal.name)
                     .font(.body)
                     .multilineTextAlignment(.leading)
                 
                 Spacer()
             }
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
     GoalsView(viewModel: OnboardingViewModel())
        .environmentObject(AppState())
 }
