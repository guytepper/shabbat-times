import SwiftUI
import SwiftData

struct RemindersView: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.modelContext) private var modelContext

  @Binding var tabSelection: Int
  @State private var imageOpacity: Double = 0
  @State private var imageScale: CGFloat = 0.5
  @State private var showImage: Bool = false
  
  private var settingsManager: SettingsManager {
    SettingsManager(modelContext: modelContext)
  }

  var body: some View {
    VStack {
      ZStack {
        RoundedRectangle(cornerRadius: 0)
          .fill(.black.opacity(0.8).gradient)
          .frame(minHeight: 0, maxHeight: .infinity)
          .ignoresSafeArea()
          .opacity(showImage ? 1 : 0)
          .animation(.easeIn(duration: 1).delay(colorScheme == .light ? 0.75 : 0), value: showImage)
        
        if showImage {
          Image("notification_example")
            .resizable()
            .scaledToFit()
            .padding(24)
            .opacity(imageOpacity)
            .scaleEffect(imageScale)
            .animation(.interpolatingSpring(stiffness: 100, damping: 25), value: imageOpacity)
        }
      }
      .onAppear {
        withAnimation {
          showImage = true
        }
        
        // Background darkening is less interruptive on dark mode
        let delay = colorScheme == .light ? 2 : 0.25
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
          imageOpacity = 1
          imageScale = 1
        }
      }
      
      Spacer()
      
      VStack(spacing: 8) {
        Text("Reminders")
          .font(.title)
          .fontWeight(.bold)
          .fontWidth(Font.Width(0.05))
        
        Text("Receive candle lightning times every friday morning.")
          .font(.body)
          .multilineTextAlignment(.center)
          .padding(.bottom, 12)
        
        Button("Enable Notifications") {
          Task {
            do {
              let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])

              if granted {
                settingsManager.updateSettings { settings in
                  settings.finishedOnboarding = true
                  
                  // Register background notification task
                  BackgroundTaskService.shared.registerBackgroundTasks()
                }
              } else {
                print("Notification permission denied.")
              }
            } catch {
              print("Error requesting notification authorization: \(error.localizedDescription)")
            }
          }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.blue)
        .foregroundColor(.white)
        .cornerRadius(16)
        .padding(.bottom, 8)
        
        Button("Not Now")  {
          settingsManager.updateSettings { settings in
            settings.finishedOnboarding = true
          }
        }
        .foregroundStyle(.black)
      }
      .padding()
    }
  }
}

#Preview {
  TabView {
    RemindersView(tabSelection: .constant(1))
      .background(Color.gradientBackground(for: .light))
  }.tabViewStyle(.page)
    .ignoresSafeArea()
}
