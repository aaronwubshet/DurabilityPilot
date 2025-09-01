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
    
    var body: some View {
        ZStack {
            Group {
                switch appState.appFlowState {
                case .loading:
                    LoadingView()
                case .unauthenticated:
                    AuthenticationView(authService: appState.authService)
                case .onboarding:
                    OnboardingFlowView()
                        .dismissKeyboardOnSwipe()
                case .assessment:
                    AssessmentFlowView()
                case .assessmentResults:
                    AssessmentFlowView()
                case .mainApp:
                    MainTabView()
                }
            }
            .background(Color.darkSpaceGrey)
        }
        .onChange(of: appState.onboardingCompleted) { _, newValue in
            // Dismiss keyboard when app state changes
            dismissKeyboard()
        }
        .onChange(of: appState.assessmentCompleted) { _, newValue in
            // Dismiss keyboard when app state changes
            dismissKeyboard()
        }
    }
    
    private func dismissKeyboard() {
        isTextFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.walk")
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
