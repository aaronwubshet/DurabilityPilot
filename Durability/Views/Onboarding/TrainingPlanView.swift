import SwiftUI

struct TrainingPlanView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showImagePicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Do you follow a training plan?")
                    .font(.title)
                    .fontWeight(.bold)
                
                Toggle("I have a training plan", isOn: $viewModel.hasTrainingPlan)
                    .font(.headline)
                
                if viewModel.hasTrainingPlan {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tell us about your plan")
                            .font(.headline)
                        
                        TextField("Describe your training plan", text: $viewModel.trainingPlanInfo, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(5...10)
                            .onChange(of: viewModel.trainingPlanInfo) { _, _ in
                                // Data will be saved when user presses Next
                            }
                        
                        if let image = viewModel.trainingPlanImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(10)
                        }
                        
                        Button(viewModel.trainingPlanImage == nil ? "Upload Plan Image (Optional)" : "Change Image") {
                            showImagePicker = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(isPresented: $showImagePicker, image: $viewModel.trainingPlanImage)
        }
        .onChange(of: viewModel.trainingPlanImage) { _, newImage in
            // Data will be saved when user presses Next
        }
        .onAppear {
            // Load existing user selections from database
            Task {
                await viewModel.loadExistingSelectionsForCurrentStep()
            }
        }
    }
}

#Preview {
    TrainingPlanView(viewModel: OnboardingViewModel())
}
