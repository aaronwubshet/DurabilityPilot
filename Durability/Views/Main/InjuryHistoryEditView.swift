import SwiftUI

struct InjuryHistoryEditView: View {
    @ObservedObject var viewModel: ProfileEditViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Edit Injury History")
                    .font(.title)
                    .fontWeight(.bold)
                
                if viewModel.isLoading {
                    ProgressView("Loading injury data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Injury history editing coming soon...")
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
        .navigationTitle("Edit Injury History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    InjuryHistoryEditView(viewModel: ProfileEditViewModel(profileId: "test"))
}
