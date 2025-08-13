import SwiftUI

struct TrainingPlanEditView: View {
    @ObservedObject var viewModel: ProfileEditViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showImagePicker = false
    @State private var showImageSourceActionSheet = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Training Plan")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.lightText)
                        
                        Text("Update your training routine and plan details")
                            .font(.subheadline)
                            .foregroundColor(.secondaryText)
                    }
                    
                    // Training Plan Toggle
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "dumbbell.fill")
                                .foregroundColor(.electricGreen)
                                .font(.title2)
                            
                            Text("I have a training plan")
                                .font(.headline)
                                .foregroundColor(.lightText)
                            
                            Spacer()
                            
                            Toggle("", isOn: $viewModel.hasTrainingPlan)
                                .toggleStyle(SwitchToggleStyle(tint: .electricGreen))
                        }
                        .padding()
                        .background(Color.lightSpaceGrey)
                        .cornerRadius(12)
                                .onChange(of: viewModel.hasTrainingPlan) { _, newValue in
            // Dismiss keyboard when toggle is turned off
            if !newValue {
                isTextFieldFocused = false
            }
        }
        .onChange(of: viewModel.trainingPlanImage) { _, newImage in
            // Reset removal flag when a new image is selected
            if newImage != nil {
                viewModel.trainingPlanImageRemoved = false
            }
        }
                    }
                    
                    // Training Plan Details
                    if viewModel.hasTrainingPlan {
                        VStack(alignment: .leading, spacing: 16) {
                            // Description Section
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "text.alignleft")
                                        .foregroundColor(.electricGreen)
                                        .font(.title3)
                                    
                                    Text("Tell us about your plan")
                                        .font(.headline)
                                        .foregroundColor(.lightText)
                                }
                                
                                TextField("Describe your training plan, schedule, or routine...", text: $viewModel.trainingPlanInfo, axis: .vertical)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .lineLimit(5...10)
                                    .focused($isTextFieldFocused)
                                    .onAppear {
                                        // Ensure keyboard doesn't automatically appear when view loads
                                        isTextFieldFocused = false
                                    }
                            }
                            
                            // Image Upload Section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "photo.fill")
                                        .foregroundColor(.electricGreen)
                                        .font(.title3)
                                    
                                    Text("Training Plan Image (Optional)")
                                        .font(.headline)
                                        .foregroundColor(.lightText)
                                }
                                
                                if let image = viewModel.trainingPlanImage {
                                    VStack(spacing: 12) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 200)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.electricGreen.opacity(0.3), lineWidth: 2)
                                            )
                                        
                                        HStack(spacing: 16) {
                                            Button(action: {
                                                showImageSourceActionSheet = true
                                            }) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "pencil")
                                                        .font(.caption)
                                                    Text("Change")
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                }
                                                .foregroundColor(.electricGreen)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.electricGreen.opacity(0.1))
                                                .cornerRadius(8)
                                            }
                                            
                                            Button(action: {
                                                viewModel.trainingPlanImage = nil
                                                viewModel.trainingPlanImageRemoved = true
                                            }) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "trash")
                                                        .font(.caption)
                                                    Text("Remove")
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                }
                                                .foregroundColor(.red)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.red.opacity(0.1))
                                                .cornerRadius(8)
                                            }
                                        }
                                    }
                                } else {
                                    Button(action: {
                                        showImageSourceActionSheet = true
                                    }) {
                                        VStack(spacing: 12) {
                                            Image(systemName: "photo.badge.plus")
                                                .font(.system(size: 40))
                                                .foregroundColor(.electricGreen)
                                            
                                            VStack(spacing: 4) {
                                                Text("Add Training Plan Image")
                                                    .font(.headline)
                                                    .foregroundColor(.lightText)
                                                
                                                Text("Upload a photo of your plan or take a picture")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondaryText)
                                                    .multilineTextAlignment(.center)
                                            }
                                        }
                                        .padding(24)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.lightSpaceGrey)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.electricGreen.opacity(0.3), lineWidth: 2)
                                        )
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color.darkSpaceGrey)
            .navigationTitle("Training Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.electricGreen)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.saveProfile()
                            if viewModel.saveSuccess {
                                dismiss()
                            }
                        }
                    }
                    .foregroundColor(.electricGreen)
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(isPresented: $showImagePicker, image: $viewModel.trainingPlanImage, sourceType: imagePickerSourceType)
        }
        .actionSheet(isPresented: $showImageSourceActionSheet) {
            ActionSheet(
                title: Text("Choose Image Source"),
                message: Text("Select where you'd like to get your training plan image from"),
                buttons: buildImageSourceButtons()
            )
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            // Load existing profile data
            Task {
                await viewModel.loadProfileData()
            }
        }
    }
    
    private func buildImageSourceButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        // Add camera option if available
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            buttons.append(.default(Text("📷 Camera")) {
                imagePickerSourceType = .camera
                showImagePicker = true
            })
        }
        
        // Add photo library option
        buttons.append(.default(Text("🖼️ Photo Library")) {
            imagePickerSourceType = .photoLibrary
            showImagePicker = true
        })
        
        // Add cancel button
        buttons.append(.cancel())
        
        return buttons
    }
}

// Note: CustomTextFieldStyle is already defined in TrainingPlanView.swift

#Preview {
    TrainingPlanEditView(viewModel: ProfileEditViewModel(profileId: "test"))
        .background(Color.darkSpaceGrey)
}
