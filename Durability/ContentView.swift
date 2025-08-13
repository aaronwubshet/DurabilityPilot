//
//  ContentView.swift
//  Durability
//
//  Created by Aaron Wubshet on 8/8/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @FocusState private var isTextFieldFocused: Bool
    @State private var showingTransitionLoading = false
    @State private var showingClearSessionAlert = false
    
    var body: some View {
        ZStack {
            Group {
                if appState.isLoading {
                    LoadingView()
                } else if showingTransitionLoading {
                    TransitionLoadingView()
                } else if !appState.isAuthenticated {
                    AuthenticationView(authService: appState.authService)
                } else if !appState.onboardingCompleted || !appState.assessmentCompleted {
                    // Show onboarding if either onboarding or assessment is not completed
                    if !appState.onboardingCompleted {
                        OnboardingFlowView()
                            .dismissKeyboardOnSwipe()
                    } else if appState.shouldShowAssessmentResults {
                        // Always show assessment results when this flag is set
                        AssessmentFlowView()
                    } else {
                        AssessmentFlowView()
                    }
                } else {
                    // Both onboarding and assessment are completed - show main app
                    MainTabView()
                }
            }
            .background(Color.darkSpaceGrey)
            
            // Clear Session Button (always visible for debugging)
            VStack {
                HStack {
                    Button(action: {
                        showingClearSessionAlert = true
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 20)
                    .padding(.top, 10)
                    Spacer()
                }
                Spacer()
            }
        }
        .alert("Clear All Session Data", isPresented: $showingClearSessionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                Task {
                    await appState.clearAllSessionData()
                }
            }
        } message: {
            Text("This will sign you out and clear all cached data. You'll need to sign in again.")
        }
        .onChange(of: appState.onboardingCompleted) { _, newValue in
            // Dismiss keyboard when app state changes
            dismissKeyboard()
            
            // Show transition loading when moving from onboarding to assessment
            if newValue == true {
                showingTransitionLoading = true
                // Hide the loading after a short delay to show the assessment
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showingTransitionLoading = false
                }
            }
        }
        .onChange(of: appState.assessmentCompleted) { _, newValue in
            // Dismiss keyboard when app state changes
            dismissKeyboard()
            
            // Show transition loading when starting a retake (moving from completed to not completed)
            if newValue == false && appState.onboardingCompleted {
                showingTransitionLoading = true
                // Hide the loading after a short delay to show the assessment
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showingTransitionLoading = false
                }
            }
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 60))
                .foregroundColor(.electricGreen)
            
            Text("Loading...")
                .font(.title2)
                .foregroundColor(.lightText)
            
            ProgressView()
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.darkSpaceGrey)
    }
}

struct TransitionLoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.walk")
                .font(.system(size: 80))
                .foregroundColor(.electricGreen)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: UUID())
            
            Text("Preparing Your Assessment")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.lightText)
            
            Text("Setting up your personalized movement assessment...")
                .font(.body)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ProgressView()
                .scaleEffect(1.2)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.darkSpaceGrey)
    }
}

// MARK: - Keyboard Dismissal Modifier
struct KeyboardDismissalModifier: ViewModifier {
    @FocusState private var isTextFieldFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .gesture(
                // Swipe down gesture to dismiss keyboard
                DragGesture()
                    .onEnded { value in
                        if value.translation.height > 50 && abs(value.translation.width) < 50 {
                            // Swipe down detected, dismiss keyboard
                            isTextFieldFocused = false
                            hideKeyboard()
                        }
                    }
            )
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Auto Keyboard Dismissal Modifier
struct AutoKeyboardDismissalModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Dismiss keyboard when view appears (if it's not a text input view)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    hideKeyboard()
                }
            }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - View Extensions for Keyboard Dismissal
extension View {
    func dismissKeyboardOnSwipe() -> some View {
        self.modifier(KeyboardDismissalModifier())
    }
    
    func autoDismissKeyboard() -> some View {
        self.modifier(AutoKeyboardDismissalModifier())
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
