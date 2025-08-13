import SwiftUI

struct AssessmentFlowView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AssessmentViewModel()
    
    // Use AppState results if available, otherwise use view model results
    private var assessmentResults: [AssessmentResult] {
        return appState.currentAssessmentResults.isEmpty ? viewModel.assessmentResults : appState.currentAssessmentResults
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.showingInstructions {
                    AssessmentInstructionsView(viewModel: viewModel)
                } else if viewModel.isRecording {
                    AssessmentRecordingView(viewModel: viewModel)
                } else if viewModel.showingResults || appState.shouldShowAssessmentResults {
                    AssessmentResultsView(viewModel: viewModel, assessmentResults: assessmentResults)
                } else {
                    AssessmentStartView(viewModel: viewModel)
                }
            }
            .background(Color.darkSpaceGrey)
            .navigationTitle("Movement Assessment")
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(Color.darkSpaceGrey)
        .onAppear {
            print("🔍 AssessmentFlowView.onAppear")
            print("   - appState.shouldShowAssessmentResults: \(appState.shouldShowAssessmentResults)")
            print("   - viewModel.showingResults: \(viewModel.showingResults)")
            print("   - viewModel.showingInstructions: \(viewModel.showingInstructions)")
            print("   - viewModel.isRecording: \(viewModel.isRecording)")
            print("   - viewModel.isLoading: \(viewModel.isLoading)")
        }
    }
}

@MainActor
class AssessmentViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showingInstructions = false
    @Published var isRecording = false
    @Published var showingResults = false
    @Published var recordingTime: TimeInterval = 0
    @Published var assessmentResults: [AssessmentResult] = []
    @Published var errorMessage: String?
    @Published var isCameraPresented = false
    @Published var videoURL: URL?

    private var timer: Timer?

    func startAssessment() {
        print("🔍 AssessmentViewModel.startAssessment()")
        print("   - This could be initial assessment or retake")
        showingInstructions = true
        print("   - Set showingInstructions to true")
    }

    func beginRecording() {
        print("🔍 AssessmentViewModel.beginRecording()")
        isRecording = true
        showingInstructions = false
        print("   - Set isRecording to true, showingInstructions to false")
        // The camera is now presented from the view
    }

    func stopRecording(appState: AppState) {
        print("🔍 AssessmentViewModel.stopRecording()")
        isRecording = false
        isCameraPresented = false
        print("   - Set isRecording to false, isCameraPresented to false")
        generateResults(appState: appState)
    }
    
    private func generateResults(appState: AppState) {
        print("🔍 AssessmentViewModel.generateResults() - Starting")
        print("   - This could be initial assessment or retake")
        isLoading = true
        
        Task {
            guard let userId = appState.authService.user?.id.uuidString else {
                print("❌ No authenticated user found")
                errorMessage = "User not authenticated"
                isLoading = false
                return
            }
            
            do {
                var assessment: Assessment?
                
                // Always create a new assessment record (even for retakes)
                // This ensures we have a complete history of all assessments
                print("🔍 Creating new assessment record for user: \(userId)")
                print("   - This creates a new assessment record (works for both initial and retake)")
                if let videoURL = videoURL {
                    print("   - Creating assessment with video")
                    assessment = try await appState.assessmentService.createAssessmentWithVideo(
                        profileId: userId,
                        videoURL: videoURL
                    )
                } else {
                    print("   - Creating assessment without video")
                    assessment = try await appState.assessmentService.createAssessmentWithoutVideo(
                        profileId: userId
                    )
                }
                
                guard let assessment = assessment else {
                    print("❌ Failed to create assessment record")
                    errorMessage = "Failed to create assessment record"
                    isLoading = false
                    return
                }

                print("✅ Assessment created successfully with ID: \(assessment.assessmentId ?? -1)")

                // Simulate assessment processing
                print("🔍 Simulating assessment processing...")
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

                // Generate assessment results for different body areas
                let bodyAreas = ["Overall", "Shoulder", "Torso", "Hips", "Knees", "Ankles", "Elbows"]
                var results: [AssessmentResult] = []

                print("🔍 Generating assessment results for \(bodyAreas.count) body areas...")
                print("   - Assessment ID: \(assessment.assessmentId?.description ?? "nil")")
                print("   - Assessment ID type: \(type(of: assessment.assessmentId))")
                print("   - Profile ID: \(userId)")
                print("   - Profile ID type: \(type(of: userId))")

                for area in bodyAreas {
                    let result = AssessmentResult(
                        id: nil, // Will be auto-generated by database
                        assessmentId: assessment.assessmentId!, // Use the integer assessment ID
                        profileId: userId, // Use the user's profile ID
                        bodyArea: area,
                        durabilityScore: Double.random(in: 0.6...0.9),
                        rangeOfMotionScore: Double.random(in: 0.5...0.9),
                        flexibilityScore: Double.random(in: 0.4...0.8),
                        functionalStrengthScore: Double.random(in: 0.6...0.9),
                        mobilityScore: Double.random(in: 0.5...0.8),
                        aerobicCapacityScore: Double.random(in: 0.7...0.9)
                    )
                    
                    print("🔍 Generated result for \(area):")
                    print("   - assessmentId: \(result.assessmentId) (type: \(type(of: result.assessmentId)))")
                    print("   - profileId: \(result.profileId) (type: \(type(of: result.profileId)))")
                    print("   - bodyArea: \(result.bodyArea) (type: \(type(of: result.bodyArea)))")
                    print("   - durabilityScore: \(result.durabilityScore) (type: \(type(of: result.durabilityScore)))")
                    print("   - rangeOfMotionScore: \(result.rangeOfMotionScore) (type: \(type(of: result.rangeOfMotionScore)))")
                    print("   - flexibilityScore: \(result.flexibilityScore) (type: \(type(of: result.flexibilityScore)))")
                    print("   - functionalStrengthScore: \(result.functionalStrengthScore) (type: \(type(of: result.functionalStrengthScore)))")
                    print("   - mobilityScore: \(result.mobilityScore) (type: \(type(of: result.mobilityScore)))")
                    print("   - aerobicCapacityScore: \(result.aerobicCapacityScore) (type: \(type(of: result.aerobicCapacityScore)))")
                    
                    results.append(result)
                }

                print("🔍 Generated \(results.count) assessment results")

                // Always create new assessment results (even for retakes)
                // This ensures we have fresh data for each assessment attempt
                print("🔍 Creating assessment results in database...")
                print("   - This creates new assessment results (works for both initial and retake)")
                print("   - Assessment ID: \(assessment.assessmentId!)")
                print("   - Results count: \(results.count)")
                print("   - First result: \(results.first?.bodyArea ?? "none")")
                
                do {
                    try await appState.assessmentService.createAssessmentResults(
                        assessmentId: assessment.assessmentId!,
                        results: results
                    )
                    print("✅ Assessment results created successfully in database")
                } catch {
                    print("❌ Failed to create assessment results in database: \(error)")
                    print("   - Error details: \(error.localizedDescription)")
                    // Continue with the flow even if database write fails
                    // The results are still generated and can be displayed
                }

                assessmentResults = results
                isLoading = false
                showingResults = true
                
                print("🔍 Setting view model state:")
                print("   - assessmentResults count: \(assessmentResults.count)")
                print("   - isLoading: \(isLoading)")
                print("   - showingResults: \(showingResults)")
                
                // Store results in AppState and set the app state to show assessment results
                await MainActor.run {
                    appState.currentAssessmentResults = results
                    appState.shouldShowAssessmentResults = true
                    print("🔍 Set appState.currentAssessmentResults with \(results.count) results")
                    print("🔍 Set appState.shouldShowAssessmentResults to true")
                }
                
            } catch {
                print("❌ Error in generateResults: \(error.localizedDescription)")
                errorMessage = "Failed to process assessment: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    
    func completeAssessment(appState: AppState) {
        print("🔍 AssessmentViewModel.completeAssessment() - Starting")
        print("   - Current appState.assessmentCompleted: \(appState.assessmentCompleted)")
        print("   - Current appState.shouldShowAssessmentResults: \(appState.shouldShowAssessmentResults)")
        
        Task {
            guard appState.authService.user?.id.uuidString != nil else {
                print("❌ No authenticated user found")
                return
            }
            
            do {
                print("🔍 Marking assessment as completed in database...")
                
                // Update user profile to mark assessment as completed
                var updatedProfile = appState.currentUser
                updatedProfile?.assessmentCompleted = true
                updatedProfile?.updatedAt = Date()
                
                if let profile = updatedProfile {
                    try await appState.profileService.updateProfile(profile)
                    
                    // Update app state to move to main app
                    await MainActor.run {
                        appState.currentUser = profile
                        appState.assessmentCompleted = true
                        appState.shouldShowAssessmentResults = false // Clear the results flag
                        print("✅ Assessment completed successfully - advancing to main app")
                        print("   - Updated appState.assessmentCompleted: \(appState.assessmentCompleted)")
                        print("   - Updated appState.shouldShowAssessmentResults: \(appState.shouldShowAssessmentResults)")
                    }
                } else {
                    print("❌ No user profile found to update")
                }
            } catch {
                print("❌ Failed to mark assessment as completed: \(error.localizedDescription)")
                // Even if database update fails, try to advance to main app
                await MainActor.run {
                    appState.assessmentCompleted = true
                    appState.shouldShowAssessmentResults = false
                    print("⚠️ Advanced to main app despite database error")
                    print("   - Updated appState.assessmentCompleted: \(appState.assessmentCompleted)")
                    print("   - Updated appState.shouldShowAssessmentResults: \(appState.shouldShowAssessmentResults)")
                }
            }
        }
    }
    
    /// Reset the view model state to start a new assessment
    func resetForNewAssessment() {
        print("🔍 AssessmentViewModel.resetForNewAssessment()")
        print("   - This is being called for a retake assessment")
        print("   - Before reset:")
        print("     * showingResults: \(showingResults)")
        print("     * showingInstructions: \(showingInstructions)")
        print("     * isRecording: \(isRecording)")
        print("     * assessmentResults count: \(assessmentResults.count)")
        
        showingResults = false
        showingInstructions = false
        isRecording = false
        assessmentResults = []
        videoURL = nil
        errorMessage = nil
        recordingTime = 0
        isCameraPresented = false
        
        print("   - After reset:")
        print("     * showingResults: \(showingResults)")
        print("     * showingInstructions: \(showingInstructions)")
        print("     * isRecording: \(isRecording)")
        print("     * assessmentResults count: \(assessmentResults.count)")
        print("   - View model is now ready for a new assessment")
    }
}

struct AssessmentStartView: View {
    @ObservedObject var viewModel: AssessmentViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "figure.walk")
                .font(.system(size: 80))
                .foregroundColor(.electricGreen)
            
            Text("Movement Assessment")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.lightText)
            
            Text("We'll assess your movement patterns to create a personalized training plan.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondaryText)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("The assessment includes:")
                    .font(.headline)
                    .foregroundColor(.lightText)
                
                VStack(alignment: .leading, spacing: 8) {
                    AssessmentStepRow(number: "1", text: "Overhead Squat")
                    AssessmentStepRow(number: "2", text: "Active Straight Leg Raise")
                    AssessmentStepRow(number: "3", text: "Shoulder Raise")
                    AssessmentStepRow(number: "4", text: "Standing Hip Hinge")
                    AssessmentStepRow(number: "5", text: "Child's Pose")
                    AssessmentStepRow(number: "6", text: "Cobra")
                }
            }
            .padding()
            .background(Color.lightSpaceGrey)
            .cornerRadius(15)
            
            Button(action: {
                print("🔍 AssessmentStartView - Start Assessment button pressed")
                viewModel.startAssessment()
            }) {
                Text("Start Assessment")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.electricGreen)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.darkSpaceGrey)
    }
}

struct AssessmentStepRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.electricGreen)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.lightText)
            
            Spacer()
        }
    }
}

#Preview {
    AssessmentFlowView()
        .environmentObject(AppState())
}
