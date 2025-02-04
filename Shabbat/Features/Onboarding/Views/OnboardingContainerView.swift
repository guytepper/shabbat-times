import SwiftUI

struct OnboardingContainerView: View {
  @Environment(\.colorScheme) var colorScheme
  @State var tabSelection = 0
  
  var body: some View {
    TabView(selection: $tabSelection) {
      WelcomeView()
      NotificationPermissionView()
    }
    .background(Color.gradientBackground(for: colorScheme))
    .tabViewStyle(.page(indexDisplayMode: .never))
    .onAppear {
      // Disable tab view scrolling
      UIScrollView.appearance().isScrollEnabled = false
    }
  }
}
