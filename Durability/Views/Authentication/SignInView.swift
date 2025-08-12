import SwiftUI

struct SignInView: View {
    
    @ObservedObject var viewModel: AuthenticationViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            Text("Sign In")
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
            SecureField("Password", text: $viewModel.password)
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
            
            // Sign In Button
            Button(action: {
                Task {
                    if await viewModel.signIn() {
                        // On success, dismiss the view. The main app view will update.
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
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
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
        .dismissKeyboardOnSwipe()
    }
}

#Preview {
    // For the preview to work, we need a dummy AuthService
    class MockAuthService: AuthService { }
    return SignInView(viewModel: AuthenticationViewModel(authService: MockAuthService()))
}

