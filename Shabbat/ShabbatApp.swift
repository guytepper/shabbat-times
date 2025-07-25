import SwiftUI
import SwiftData

@main
struct ShabbatApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  init() {
    // Register background task
    BackgroundTaskService.shared.registerBackgroundTasks()
    
    // RocketSim network monitoring
    loadRocketSimConnect()
  }
  
  var body: some Scene {
    WindowGroup {
      MainView()
        .modelContainer(for: [City.self, Settings.self])
        .onAppear {
          // Track app opens for rating prompts
          RatingManager.shared.incrementUsageCount()
        }
    }
  }
  
  private func loadRocketSimConnect() {
      #if DEBUG
      guard (Bundle(path: "/Applications/RocketSim.app/Contents/Frameworks/RocketSimConnectLinker.nocache.framework")?.load() == true) else {
          print("Failed to load linker framework")
          return
      }
      print("RocketSim Connect successfully linked")
      #endif
  }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return true
  }
  
  // Handle notifications when the app is in the foreground
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound, .list])
  }
}

struct MainView: View {
  @Query private var cities: [City]
  @Query private var settings: [Settings]
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
