import SwiftUI
import SwiftData

@main
struct ShabbatApp: App {
  var body: some Scene {
    WindowGroup {
      MainView()
        .modelContainer(for: City.self)
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
        HomeView(modelContext: modelContext)
           .transition(
              .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
              ))
      }
    }
    .transition(.opacity.combined(with: .move(edge: .trailing)))
    .animation(
      .spring(duration: 0.5, bounce: 0.2).delay(0.3),
      value: cities.isEmpty
    )
  }
}
