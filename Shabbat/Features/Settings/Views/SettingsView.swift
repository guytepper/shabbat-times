import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.modelContext) private var modelContext
  @State private var settingsManager: SettingsManager
  @State private var showCredits = false
  
  init(modelContext: ModelContext) {
    self.settingsManager = SettingsManager(modelContext: modelContext)
  }
  
  var settings: Settings {
    settingsManager.settings
  }
    
  func removePendingNotifications() {
    let center = UNUserNotificationCenter.current()
    center.removeAllPendingNotificationRequests()
  }
  
  var body: some View {
    NavigationStack {
        List {
          Section("Notifications") {
            VStack(alignment: .leading, spacing: 6) {
              Toggle("🌞 Morning Notification", isOn: Binding(
                get: { settings.morningNotification },
                set: { newValue in
                  settingsManager.updateSettings { settings in
                    settings.morningNotification = newValue
                  }
                  
                  if newValue == false {
                    removePendingNotifications()
                  } else {
                    BackgroundTaskService.shared.scheduleAppRefresh(Date())
                  }
                }
              ))
              
              Text("Friday morning shabbat times notification.")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
              Toggle("🕯️ Candle Lighting", isOn: Binding(
                get: { settings.candleLightningNotification },
                set: { newValue in
                  settingsManager.updateSettings { settings in
                    settings.candleLightningNotification = newValue
                  }
                  
                  removePendingNotifications()
                  BackgroundTaskService.shared.scheduleAppRefresh(Date())
                }
              ))
              
              Text("Receive a notification prior to the candle lighting time.")
                .font(.caption)
                .foregroundStyle(.secondary)
              
              if settings.candleLightningNotification {
                Picker("Notification Time", selection: Binding(
                  get: { settings.candleLightingNotificationMinutes },
                  set: { newValue in
                    settingsManager.updateSettings { settings in
                      settings.candleLightingNotificationMinutes = newValue
                    }
                    // Reschedule notifications with new time
                    BackgroundTaskService.shared.scheduleAppRefresh(Date())
                  }
                )) {
                  ForEach([10, 15, 30, 45, 60], id: \.self) { minutes in
                    Text(String(localized: "\(minutes) minutes before")).tag(minutes)
                  }
                }
                .padding(.top, 12)
              }
            }
          }
          
          Section {
            Button("🙏 Credits") {
              showCredits = true
            }
            .foregroundStyle(Color(uiColor: .label))
            
            Button("📨 Send Feedback") {
              if let url = URL(string: "mailto:hey@guytepper.com") {
                UIApplication.shared.open(url)
              }
            }
            .foregroundStyle(Color(uiColor: .label))
          }
          
          #if DEBUG
            NotificationDebugView()
          #endif
        }
      .navigationTitle("Settings")
      .background(Color.gradientBackground(for: colorScheme))
      .scrollContentBackground(.hidden)
      .sheet(isPresented: $showCredits) {
        CreditsView()
      }
    }
  }
}

#Preview {
  let container = try! ModelContainer(
    for: Settings.self,
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
  )
  
  SettingsView(modelContext: container.mainContext)
    .modelContainer(container)
}
