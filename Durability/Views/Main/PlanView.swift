import SwiftUI

struct PlanView: View {
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
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.circle")
                    }
                }
            }
        }
    }
}

#Preview {
    PlanView()
}
