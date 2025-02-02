import SwiftUI
import SwiftData

@main
struct ShabbatApp: App {
  var body: some Scene {
    WindowGroup {
      MainView()
        .modelContainer(for: [City.self, Settings.self])
    }
  }
}

struct MainView: View {
  @Query private var cities: [City]
  @Environment(\.modelContext) private var modelContext
  
  var body: some View {
    Group {
      if cities.isEmpty {
        OnboardingView()
      } else {
        TabView {
          HomeView(modelContext: modelContext)
            .tabItem {
              Label("Shabbat Times", systemImage: "clock")
            }
          
          SettingsView(modelContext: modelContext)
            .tabItem {
              Label("Settings", systemImage: "gearshape")
            }
        }
      }
    }
    .transition(.opacity.combined(with: .move(edge: .trailing)))
  }
}
