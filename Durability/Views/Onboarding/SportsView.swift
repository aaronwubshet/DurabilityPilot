import SwiftUI

struct SportsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var appState: AppState
     @State private var sports: [Sport] = []
     private let defaultSports: [(name: String, icon: String)] = [
         ("Soccer", "soccerball"),
         ("Basketball", "basketball"),
         ("Football", "figure.american.football"),
         ("Tennis", "tennis.racket"),
         ("Short distance running", "figure.run"),
         ("Mid distance running", "figure.run.circle"),
         ("Long distance running", "figure.run.square"),
         ("Triathlons", "bicycle"),
         ("CrossFit", "dumbbell"),
         ("Hyrox", "figure.strengthtraining.traditional")
     ]
     
     var body: some View {
         ScrollView {
             VStack(alignment: .leading, spacing: 20) {
                 Text("What sports do you participate in?")
                     .font(.title)
                     .fontWeight(.bold)
                 
                 Text("Select all that apply")
                     .font(.subheadline)
                     .foregroundColor(.secondary)
                 
                  LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                      ForEach(sports) { sport in
                          SportCard(
                              sport: sport,
                              iconName: iconForSport(named: sport.name),
                              isSelected: viewModel.selectedSports.contains(sport.id)
                          ) {
                              if viewModel.selectedSports.contains(sport.id) {
                                  viewModel.selectedSports.remove(sport.id)
                              } else {
                                  viewModel.selectedSports.insert(sport.id)
                              }
                          }
                      }
                  }
                 
                 Spacer()
             }
             .padding()
         }
         .onAppear {
             loadSports()
         }
     }
     
     private func loadSports() {
         Task {
             do {
                  let fetched = try await appState.profileService.getSports()
                  if fetched.isEmpty {
                      // Fallback defaults
                      self.sports = defaultSports.enumerated().map { idx, pair in
                          Sport(id: idx + 1, name: pair.name)
                      }
                  } else {
                      self.sports = fetched
                  }
             } catch {
                  // Fallback defaults on error
                  self.sports = defaultSports.enumerated().map { idx, pair in
                      Sport(id: idx + 1, name: pair.name)
                  }
             }
         }
     }

     private func iconForSport(named name: String) -> String {
         let normalized = name.lowercased()
         for pair in defaultSports {
             if pair.name.lowercased() == normalized { return pair.icon }
         }
         // Heuristics for common variants
         if normalized.contains("soccer") { return "soccerball" }
         if normalized.contains("basket") { return "basketball" }
         if normalized.contains("football") { return "figure.american.football" }
         if normalized.contains("tennis") { return "tennis.racket" }
         if normalized.contains("run") { return "figure.run" }
         if normalized.contains("tri") { return "bicycle" }
         if normalized.contains("cross") { return "dumbbell" }
         if normalized.contains("hyrox") { return "figure.strengthtraining.traditional" }
         return "sportscourt"
     }
 }

 struct SportCard: View {
     let sport: Sport
      let iconName: String
     let isSelected: Bool
     let onTap: () -> Void
     
     var body: some View {
         Button(action: onTap) {
             VStack {
                  Image(systemName: iconName)
                     .font(.title2)
                      .foregroundColor(isSelected ? .accentColor : .secondary)
                 
                 Text(sport.name)
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
     SportsView(viewModel: OnboardingViewModel())
        .environmentObject(AppState())
 }
