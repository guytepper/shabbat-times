import SwiftUI

struct OnboardingContainerView: View {
  @Environment(\.colorScheme) private var colorScheme
  @State private var tabSelection = 0
  
  var body: some View {
    TabView(selection: $tabSelection) {
      WelcomeView(tabSelection: $tabSelection)
        .tag(0)
      NotificationPermissionView(tabSelection: $tabSelection)
        .tag(1)
    }
    .background(Color.gradientBackground(for: colorScheme))
    .tabViewStyle(.page(indexDisplayMode: .never))
    .ignoresSafeArea()
    .onAppear {
      // Disable tab view scrolling
      UIScrollView.appearance().isScrollEnabled = false
    }
  }
}

#Preview {
  OnboardingContainerView()
}
