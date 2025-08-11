import SwiftUI

struct SignUpView: View {
    
    @ObservedObject var viewModel: AuthenticationViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Email Field
            TextField("Email", text: $viewModel.email)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            // Password Field
            SecureField("Password (at least 6 characters)", text: $viewModel.password)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            // Confirm Password Field
            SecureField("Confirm Password", text: $viewModel.confirmPassword)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            // Error Message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Spacer()
            
            // Create Account Button
            Button(action: {
                Task {
                    if await viewModel.signUp() {
                        // On success, dismiss the view.
                        // The user will need to check their email for confirmation.
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Account")
                    }
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canSubmit ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!viewModel.canSubmit || viewModel.isLoading)
            
        }
        .padding()
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {
    // For the preview to work, we need a dummy AuthService
    class MockAuthService: AuthService { }
    return SignUpView(viewModel: AuthenticationViewModel(authService: MockAuthService()))
}

