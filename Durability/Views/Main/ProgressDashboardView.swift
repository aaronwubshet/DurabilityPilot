import SwiftUI

struct ProgressDashboardView: View {
    @StateObject private var viewModel = ProgressViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkSpaceGrey
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if viewModel.isLoading {
                            ProgressView("Loading progress...")
                        } else if let latestResult = viewModel.latestAssessmentResult {
                            // Overall Durability Score
                            OverallDurabilityView(score: latestResult.durabilityScore)

                            // Super Metrics Radar Chart
                            SuperMetricsRadarChartView(
                                results: viewModel.latestAssessmentResult,
                                history: viewModel.assessmentHistory
                            )

                            // Super Metrics Breakdown
                            SuperMetricsBreakdownView(result: latestResult)

                        } else {
                            Text("No assessment data found.")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .onAppear {
                viewModel.loadProgressData(appState: appState)
            }
        }
    }
}

#Preview {
    ProgressDashboardView()
        .environmentObject(AppState())
}

