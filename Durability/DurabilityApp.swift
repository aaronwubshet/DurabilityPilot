//
//  DurabilityApp.swift
//  Durability
//
//  Created by Aaron Wubshet on 8/8/25.
//

import SwiftUI
import Supabase

@main
struct DurabilityApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    configureAppearance()
                }
        }
    }
    
    private func configureAppearance() {
        // Define dark space grey colors
        let darkSpaceGrey = UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0) // Dark space grey
        let darkerSpaceGrey = UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0) // Even darker for contrast
        let lightTextColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0) // Light text for contrast
        
        // Configure navigation bar appearance
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = darkSpaceGrey
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: lightTextColor]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: lightTextColor]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = darkerSpaceGrey
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Set global background color
        UITableView.appearance().backgroundColor = darkSpaceGrey
        UIScrollView.appearance().backgroundColor = darkSpaceGrey
        
        // Set TabView background color
        UITabBar.appearance().backgroundColor = darkerSpaceGrey
    }
}
