import SwiftUI

struct OnboardingContainerView: View {
  @Environment(\.colorScheme) var colorScheme
  
  var body: some View {
    TabView {
      WelcomeView()
      NotificationPermissionView()
    }
    .background(Color.gradientBackground(for: colorScheme))
    .tabViewStyle(.page(indexDisplayMode: .never))

  }
}
