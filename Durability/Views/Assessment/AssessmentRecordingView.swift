import SwiftUI

struct AssessmentRecordingView: View {
    @ObservedObject var viewModel: AssessmentViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            // This view will now primarily be a placeholder
            // that launches the camera.
            Text("Ready to Record")
                .font(.largeTitle)
        }
        .onAppear {
            viewModel.isCameraPresented = true
        }
        .sheet(isPresented: $viewModel.isCameraPresented) {
            CameraView(isPresented: $viewModel.isCameraPresented) { videoURL in
                viewModel.videoURL = videoURL
                viewModel.stopRecording(appState: appState)
            }
        }
    }
}

#Preview {
    AssessmentRecordingView(viewModel: AssessmentViewModel())
        .environmentObject(AppState())
}
