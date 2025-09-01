import SwiftUI

struct AssessmentInstructionsView: View {
    @ObservedObject var viewModel: AssessmentViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Assessment Instructions")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("You will now complete a 6-step movement assessment consisting of an overhead squat, active straight leg raise, shoulder raise, standing hip hinge, child's pose, and cobra.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Important Notes:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InstructionRow(icon: "video.fill", text: "Record all movements in a single video")
                        InstructionRow(icon: "clock.fill", text: "Maximum recording time: 3 minutes")
                        InstructionRow(icon: "figure.walk", text: "Perform each movement naturally")
                        InstructionRow(icon: "exclamationmark.triangle.fill", text: "Stop if you feel any pain or discomfort")
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(15)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Movement Sequence:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        MovementInstructionRow(number: "1", name: "Overhead Squat", text: "Hold arms overhead, squat down and up")
                        MovementInstructionRow(number: "2", name: "Active Straight Leg Raise", text: "Lie on back, raise one leg straight up")
                        MovementInstructionRow(number: "3", name: "Shoulder Raise", text: "Stand with arms at sides, raise overhead")
                        MovementInstructionRow(number: "4", name: "Standing Hip Hinge", text: "Bend forward at hips, keep legs straight")
                        MovementInstructionRow(number: "5", name: "Child's Pose", text: "Kneel, sit back on heels, reach forward")
                        MovementInstructionRow(number: "6", name: "Cobra", text: "Lie face down, press up to lift chest")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                
                VStack(spacing: 12) {
                    Button(action: {
                        viewModel.beginRecording()
                    }) {
                        HStack {
                            Image(systemName: "video.fill")
                            Text("Start Recording")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        appState.appFlowState = .mainApp
                    }) {
                        Text("Back to Home")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.clear)
                            .foregroundColor(.secondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.secondary, lineWidth: 1)
                            )
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

struct InstructionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

struct MovementInstructionRow: View {
    let number: String
    let name: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.accentColor)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(text)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    AssessmentInstructionsView(viewModel: AssessmentViewModel())
}
