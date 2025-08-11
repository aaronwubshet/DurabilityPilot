//
//  ContentView.swift
//  Durability
//
//  Created by Aaron Wubshet on 8/8/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isLoading {
                LoadingView()
            } else if !appState.isAuthenticated {
                AuthenticationView(authService: appState.authService)
            } else if !appState.onboardingCompleted {
                OnboardingFlowView()
            } else if !appState.assessmentCompleted {
                AssessmentFlowView()
            } else {
                MainTabView()
            }
        }
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

#Preview {
    ContentView()
        .environmentObject(AppState())
}
