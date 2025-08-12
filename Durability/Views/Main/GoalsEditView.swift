import SwiftUI

struct GoalsEditView: View {
    @ObservedObject var viewModel: ProfileEditViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Edit Goals")
                    .font(.title)
                    .fontWeight(.bold)
                
                if viewModel.isLoading {
                    ProgressView("Loading goals data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Goals editing coming soon...")
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
        .navigationTitle("Edit Goals")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    GoalsEditView(viewModel: ProfileEditViewModel(profileId: "test"))
}
