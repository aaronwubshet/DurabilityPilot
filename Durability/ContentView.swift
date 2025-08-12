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
        Group {
            if appState.isLoading {
                LoadingView()
            } else if !appState.isAuthenticated {
                AuthenticationView(authService: appState.authService)
            } else if !appState.onboardingCompleted {
                OnboardingFlowView()
                    .dismissKeyboardOnSwipe()
            } else if !appState.assessmentCompleted {
                AssessmentFlowView()
            } else {
                MainTabView()
            }
        }
        .onChange(of: appState.onboardingCompleted) { _, newValue in
            print("ContentView: onboardingCompleted changed to: \(newValue)")
        }
        .onChange(of: appState.assessmentCompleted) { _, newValue in
            print("ContentView: assessmentCompleted changed to: \(newValue)")
        }
        .overlay(
            // Temporary debug button to clear session data
            VStack {
                HStack {
                    Spacer()
                    Button("Clear Session") {
                        Task {
                            await appState.clearAllSessionData()
                        }
                    }
                    .font(.caption)
                    .padding(8)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding()
                }
                Spacer()
            }
        )
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Loading...")
                .font(.title2)
                .foregroundColor(.secondary)
            
            ProgressView()
                .padding()
        }
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

// MARK: - View Extension for Keyboard Dismissal
extension View {
    func dismissKeyboardOnSwipe() -> some View {
        self.modifier(KeyboardDismissalModifier())
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
