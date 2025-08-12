import SwiftUI

struct DatabaseTestView: View {
    @EnvironmentObject var appState: AppState
    @State private var testResult: String = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "externaldrive")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Database Test")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Testing database write permissions")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(spacing: 15) {
                Button(action: {
                    Task {
                        await testDatabaseWrite()
                    }
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "pencil")
                        }
                        Text("Write 'Aaron' to Database")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                
                if !testResult.isEmpty {
                    Text(testResult)
                        .font(.caption)
                        .foregroundColor(testResult.contains("✅") ? .green : .red)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Spacer()
            
            Button("Continue to HealthKit") {
                // This will be handled by the onboarding flow
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
    
    private func testDatabaseWrite() async {
        isLoading = true
        testResult = ""
        
        guard let userId = appState.authService.user?.id.uuidString else {
            testResult = "❌ No authenticated user found"
            isLoading = false
            return
        }
        
        do {
            // Simple write to the profiles table
            let supabase = SupabaseManager.shared.client
            
            try await supabase
                .from("profiles")
                .upsert([
                    "id": userId,
                    "first_name": "Aaron"
                ])
                .execute()
            
            testResult = "✅ Successfully wrote 'Aaron' to first_name column"
            
        } catch {
            testResult = "❌ Write failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

#Preview {
    DatabaseTestView()
        .environmentObject(AppState())
}
