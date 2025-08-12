import SwiftUI

struct EquipmentEditView: View {
    @ObservedObject var viewModel: ProfileEditViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Edit Equipment")
                    .font(.title)
                    .fontWeight(.bold)
                
                if viewModel.isLoading {
                    ProgressView("Loading equipment data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Equipment editing coming soon...")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
            .padding()
        }
        .onAppear {
            Task {
                await viewModel.loadProfileData()
            }
        }
        .navigationTitle("Edit Equipment")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    EquipmentEditView(viewModel: ProfileEditViewModel(profileId: "test"))
}
