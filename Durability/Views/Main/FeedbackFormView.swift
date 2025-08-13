import SwiftUI
import MessageUI

struct FeedbackFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FeedbackFormViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Help & Support")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("We're here to help! Describe your issue below and we'll get back to you as soon as possible.")
                            .font(.body)
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Feedback Form
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Issue Description")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        TextEditor(text: $viewModel.issueDescription)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(Color.lightSpaceGrey)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.electricGreen.opacity(0.3), lineWidth: 1)
                            )
                            .onTapGesture {
                                if viewModel.issueDescription.isEmpty {
                                    viewModel.issueDescription = ""
                                }
                            }
                        
                        if viewModel.issueDescription.isEmpty {
                            Text("Please describe the issue you're experiencing...")
                                .foregroundColor(.secondaryText)
                                .font(.body)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(20)
                    .background(Color.lightSpaceGrey)
                    .cornerRadius(16)
                    
                    // User Info (Auto-filled)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 8) {
                            InfoRow(label: "Name", value: viewModel.userName)
                            InfoRow(label: "Email", value: viewModel.userEmail)
                            InfoRow(label: "App Version", value: viewModel.appVersion)
                        }
                    }
                    .padding(20)
                    .background(Color.lightSpaceGrey)
                    .cornerRadius(16)
                    
                    // Send Button
                    Button(action: {
                        viewModel.sendFeedback()
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            
                            Text(viewModel.isLoading ? "Sending..." : "Send Feedback")
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            viewModel.canSend ? Color.electricGreen : Color.gray.opacity(0.5)
                        )
                        .cornerRadius(12)
                    }
                    .disabled(!viewModel.canSend || viewModel.isLoading)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
            }
            .background(Color.darkSpaceGrey)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.electricGreen)
                }
            }
        }
        .onAppear {
            viewModel.loadUserInfo(appState: appState)
        }
        .sheet(isPresented: $viewModel.showingMailComposer) {
            MailComposeView(
                issueDescription: viewModel.issueDescription,
                userName: viewModel.userName,
                userEmail: viewModel.userEmail,
                appVersion: viewModel.appVersion,
                onDismiss: {
                    viewModel.showingMailComposer = false
                    // Always dismiss and return to Profile & Settings page
                    dismiss()
                }
            )
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondaryText)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}

// MARK: - Mail Compose View
struct MailComposeView: UIViewControllerRepresentable {
    let issueDescription: String
    let userName: String
    let userEmail: String
    let appVersion: String
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        
        // Set up email
        mailComposer.setToRecipients(["hello@mydurability.ai"])
        mailComposer.setSubject("Durability App Feedback - \(userName)")
        
        let emailBody = """
        Hi Durability Team,
        
        I'm experiencing an issue with the Durability app and would like to report it:
        
        **Issue Description:**
        \(issueDescription)
        
        **User Information:**
        - Name: \(userName)
        - Email: \(userEmail)
        - App Version: \(appVersion)
        - Device: \(UIDevice.current.model)
        - iOS Version: \(UIDevice.current.systemVersion)
        
        Please let me know if you need any additional information.
        
        Best regards,
        \(userName)
        """
        
        mailComposer.setMessageBody(emailBody, isHTML: false)
        
        return mailComposer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onDismiss: () -> Void
        
        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true) {
                // Always call onDismiss to return to Profile & Settings page
                // regardless of whether email was sent, saved as draft, or cancelled
                self.onDismiss()
            }
        }
    }
}

// MARK: - Feedback Form ViewModel
@MainActor
class FeedbackFormViewModel: ObservableObject {
    @Published var issueDescription = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingMailComposer = false
    @Published var emailSent = false
    
    // User info
    @Published var userName = ""
    @Published var userEmail = ""
    @Published var appVersion = ""
    
    var canSend: Bool {
        !issueDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func loadUserInfo(appState: AppState) {
        // Get user name
        if let user = appState.currentUser {
            userName = "\(user.firstName) \(user.lastName)".trimmingCharacters(in: .whitespaces)
        } else {
            userName = "Unknown User"
        }
        
        // Get user email
        userEmail = appState.authService.user?.email ?? "unknown@email.com"
        
        // Get app version
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = version
        } else {
            appVersion = "Unknown"
        }
    }
    
    func sendFeedback() {
        guard canSend else { return }
        
        // Check if device can send emails
        guard MFMailComposeViewController.canSendMail() else {
            errorMessage = "Email is not available on this device. Please contact us directly at hello@mydurability.ai"
            return
        }
        
        showingMailComposer = true
    }
}

#Preview {
    FeedbackFormView()
        .environmentObject(AppState())
}
