import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Inicio", systemImage: "newspaper.fill")
                }
            
            FleetView()
                .tabItem {
                    Label("Flota", systemImage: "ferry.fill")
                }
            
            ChatListView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                
            ScheduleView()
                .tabItem {
                    Label("Agenda", systemImage: "calendar")
                }
            
            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: "person.crop.circle")
                }
        }
        .accentColor(ColorTheme.fallbackAccent)
    }
}
