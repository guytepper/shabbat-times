import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.modelContext) private var modelContext
  @State private var settingsManager: SettingsManager
  @State private var pendingNotifications: [UNNotificationRequest] = []
  
  init(modelContext: ModelContext) {
    self.settingsManager = SettingsManager(modelContext: modelContext)
  }
  
  var settings: Settings {
    settingsManager.settings
  }
  
  func fetchPendingNotifications() async {
    let center = UNUserNotificationCenter.current()
    pendingNotifications = await center.pendingNotificationRequests()
  }
  
  func removePendingNotifications() {
    let center = UNUserNotificationCenter.current()
    center.removeAllPendingNotificationRequests()
  }
  
  var body: some View {
    NavigationStack {
      List {
        Section {
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
        
        #if DEBUG
        Section("Debug - Pending Notifications") {
          Text("Count: \(pendingNotifications.count)")
          
          ForEach(pendingNotifications, id: \.identifier) { notification in
            VStack(alignment: .leading, spacing: 4) {
              Text("ID: \(notification.identifier)")
                .font(.caption)
                .foregroundStyle(.secondary)
              
              if let trigger = notification.trigger as? UNCalendarNotificationTrigger,
                 let nextDate = trigger.nextTriggerDate() {
                Text("Next trigger: \(nextDate.formatted())")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              
              Text("Title: \(notification.content.title)")
                .font(.caption)
                .foregroundStyle(.secondary)
              
              if !notification.content.body.isEmpty {
                Text("Body: \(notification.content.body)")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              
              if !notification.content.userInfo.isEmpty {
                Text("User Info: \(String(describing: notification.content.userInfo))")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
            .padding(.vertical, 4)
          }
        }
        #endif
      }
      .navigationTitle("Settings")
      .background(Color.gradientBackground(for: colorScheme))
      .scrollContentBackground(.hidden)
      .task {
        #if DEBUG
        await fetchPendingNotifications()
        #endif
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
