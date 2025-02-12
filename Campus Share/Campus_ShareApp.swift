//
//  Campus_ShareApp.swift
//  Campus Share
//
//  Created by Yaduraj Singh on 10/02/25.
//

import SwiftUI

@main
struct Campus_ShareApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
            } else {
                OnboardingView()
                    .environmentObject(authManager)
            }
        }
    }
}
