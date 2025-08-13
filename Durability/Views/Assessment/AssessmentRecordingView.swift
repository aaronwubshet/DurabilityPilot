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
            print("🔍 AssessmentRecordingView.onAppear")
            print("   - Setting isCameraPresented to true")
            viewModel.isCameraPresented = true
        }
        .onChange(of: viewModel.isCameraPresented) { _, newValue in
            if newValue {
                print("🔍 Camera sheet presented")
            }
        }
        .sheet(isPresented: $viewModel.isCameraPresented) {
            CameraView(isPresented: $viewModel.isCameraPresented) { videoURL in
                print("🔍 CameraView returned video URL: \(videoURL)")
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
