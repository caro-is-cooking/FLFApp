import SwiftUI

@main
struct FLFAppApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(appState)
            } else {
                HomeView()
                    .environmentObject(appState)
            }
        }
    }
}
