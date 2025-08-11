import SwiftUI

struct AssessmentFlowView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AssessmentViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.showingInstructions {
                    AssessmentInstructionsView(viewModel: viewModel)
                } else if viewModel.isRecording {
                    AssessmentRecordingView(viewModel: viewModel)
                } else if viewModel.showingResults {
                    AssessmentResultsView(viewModel: viewModel)
                } else {
                    AssessmentStartView(viewModel: viewModel)
                }
            }
            .navigationTitle("Movement Assessment")
            .navigationBarTitleDisplayMode(.inline)
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
        showingInstructions = true
    }

    func beginRecording() {
        isRecording = true
        showingInstructions = false
        // The camera is now presented from the view
    }

    func stopRecording(appState: AppState) {
        isRecording = false
        isCameraPresented = false
        generateResults(appState: appState)
    }
    
    private func generateResults(appState: AppState) {
        isLoading = true
        
        Task {
            // Upload video if available
            if let videoURL = videoURL {
                do {
                    let uploadedVideoURL = try await appState.storageService.uploadVideo(
                        from: videoURL,
                        bucket: "assessment-videos"
                    )
                    // TODO: Save video URL to assessment record
                    print("Video uploaded successfully: \(uploadedVideoURL)")
                } catch {
                    errorMessage = "Failed to upload video: \(error.localizedDescription)"
                }
            }

            // Simulate assessment processing
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            // Generate random results for now
            let bodyAreas = ["Overall", "Shoulder", "Torso", "Hips", "Knees", "Ankles", "Elbows"]
            var results: [AssessmentResult] = []

            for area in bodyAreas {
                let result = AssessmentResult(
                    id: UUID().uuidString,
                    assessmentId: UUID().uuidString, // This should be linked to a real assessment
                    bodyArea: area,
                    durabilityScore: Double.random(in: 0.6...0.9),
                    rangeOfMotionScore: Double.random(in: 0.5...0.9),
                    flexibilityScore: Double.random(in: 0.4...0.8),
                    functionalStrengthScore: Double.random(in: 0.6...0.9),
                    mobilityScore: Double.random(in: 0.5...0.8),
                    aerobicCapacityScore: Double.random(in: 0.7...0.9)
                )
                results.append(result)
            }

            assessmentResults = results
            isLoading = false
            showingResults = true
        }
    }

    
    func completeAssessment() {
        // Mark assessment as completed and generate plan
        Task {
            // TODO: Save assessment results to database
            // TODO: Generate personalized plan
        }
    }
}

struct AssessmentStartView: View {
    @ObservedObject var viewModel: AssessmentViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "figure.walk")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("Movement Assessment")
                .font(.title)
                .fontWeight(.bold)
            
            Text("We'll assess your movement patterns to create a personalized training plan.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("The assessment includes:")
                    .font(.headline)
                
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
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)
            
            Button(action: {
                viewModel.startAssessment()
            }) {
                Text("Start Assessment")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
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
                .background(Color.accentColor)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

#Preview {
    AssessmentFlowView()
        .environmentObject(AppState())
}
