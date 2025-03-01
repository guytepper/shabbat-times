import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.modelContext) private var modelContext
  @State private var settingsManager: SettingsManager
  
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
            Toggle("Morning Notification", isOn: Binding(
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
            Toggle("Candle Lighting", isOn: Binding(
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
          VStack(alignment: .leading, spacing: 6) {
            Picker("Parasha Language", selection: Binding(
              get: { settings.parashaLanguage },
              set: { newValue in
                settingsManager.updateSettings { settings in
                  settings.parashaLanguage = newValue
                }})) {
                  Text("English").tag("en")
                  Text("Hebrew").tag("he")
                  Text("Bilingual").tag("bi")
                }
            
            Text("Reading the Parasha on the Sefaria website will be in the chosen language.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

//        #if DEBUG
        NotificationDebugView()
//        #endif
      }
      .navigationTitle("Settings")
      .background(Color.gradientBackground(for: colorScheme))
      .scrollContentBackground(.hidden)
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
