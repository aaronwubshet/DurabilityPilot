import SwiftUI

struct SportsEditView: View {
    @ObservedObject var viewModel: ProfileEditViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Edit Sports")
                    .font(.title)
                    .fontWeight(.bold)
                
                if viewModel.isLoading {
                    ProgressView("Loading sports data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Sports editing coming soon...")
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
        .navigationTitle("Edit Sports")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SportsEditView(viewModel: ProfileEditViewModel(profileId: "test"))
}
