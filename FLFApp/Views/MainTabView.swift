import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            OverviewView()
                .tabItem { Label("Overview", systemImage: "chart.xyaxis.line") }
                .tag(0)
            
            WeighInView()
                .tabItem { Label("Weigh In", systemImage: "scalemass.fill") }
                .tag(1)
            
            SupportChatView()
                .tabItem { Label("Support", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(2)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
