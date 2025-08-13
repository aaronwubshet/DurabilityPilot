import Foundation
import SwiftUI

@MainActor
class ProgressViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var assessmentHistory: [Assessment] = []
    @Published var latestAssessmentResult: AssessmentResult?
    @Published var errorMessage: String?

    func loadProgressData(appState: AppState) {
        self.isLoading = true
        Task {
            do {
                guard let profileId = appState.currentUser?.id else {
                    errorMessage = "User profile not found."
                    isLoading = false
                    return
                }

                // Fetch assessment history
                let history = try await appState.assessmentService.getAssessmentHistory(profileId: profileId)
                self.assessmentHistory = history

                // Get the latest assessment and its results
                if let latestAssessment = history.first, let assessmentId = latestAssessment.assessmentId {
                    let results = try await appState.assessmentService.getAssessmentResults(assessmentId: assessmentId)
                    // We need to find the "Overall" result to display
                    self.latestAssessmentResult = results.first(where: { $0.bodyArea == "Overall" })
                }
                
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to load progress data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

