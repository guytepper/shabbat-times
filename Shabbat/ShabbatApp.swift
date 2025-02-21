import SwiftUI
import SwiftData

@main
struct ShabbatApp: App {
  init() {
    // Register background task
    BackgroundTaskService.shared.registerBackgroundTasks()
  }
  
  var body: some Scene {
    WindowGroup {
      MainView()
        .modelContainer(for: [City.self, Settings.self])
    }
  }
}

struct MainView: View {
  @Query private var cities: [City]
  @Query private var settings: [Settings]
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.modelContext) private var modelContext
  @State private var isOnboarding: Bool = true // Track onboarding status

  var body: some View {
    ZStack {
      if isOnboarding {
        OnboardingContainerView()
          .onAppear {
            // Update onboarding status based on settings
            isOnboarding = settings.first?.finishedOnboarding != true
          }
          .transition(.move(edge: .top)) // Apply slide-up transition for onboarding
      } else {
        TabView {
          HomeView(modelContext: modelContext)
            .tabItem {
              Label("Shabbat Times", systemImage: "clock")
            }
            .onAppear {
              BackgroundTaskService.shared.scheduleAppRefresh(Date())
            }
          
          SettingsView(modelContext: modelContext)
            .tabItem {
              Label("Settings", systemImage: "gearshape")
            }
        }
      }
    }
    .onChange(of: settings.first?.finishedOnboarding) { oldValue, newValue in
      // Update onboarding status when settings change
      withAnimation {
        isOnboarding = newValue != true
      }
    }
  }
}
