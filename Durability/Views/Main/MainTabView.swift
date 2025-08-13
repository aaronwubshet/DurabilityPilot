import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Int = 1 // 0 = Plan, 1 = Today, 2 = Progress
    @State private var showingProfile = false
    
    var body: some View {
        ZStack {
            Color.darkSpaceGrey
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                PlanView(showingProfile: $showingProfile)
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Plan")
                    }
                    .tag(0)
                
                TodayWorkoutView(showingProfile: $showingProfile)
                    .tabItem {
                        Image(systemName: "figure.walk")
                        Text("Today")
                    }
                    .tag(1)
                
                ProgressDashboardView(showingProfile: $showingProfile)
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Progress")
                    }
                    .tag(2)
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
