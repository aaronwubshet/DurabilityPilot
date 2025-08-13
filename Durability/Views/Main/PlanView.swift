import SwiftUI

struct PlanView: View {
    @Binding var showingProfile: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkSpaceGrey
                    .ignoresSafeArea()
                
                VStack {
                    Text("Training Plan")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Coming soon...")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .navigationTitle("Plan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingProfile = true
                    }) {
                        Image(systemName: "person.circle")
                    }
                }
            }
        }
    }
}

#Preview {
    PlanView(showingProfile: .constant(false))
}
