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
  
  private var appVersion: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
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
              .accessibilityLabel("Morning Notification")
              .accessibilityHint("Friday morning shabbat times notification.")
              
              Text("Friday morning shabbat times notification.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
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
              .accessibilityLabel("Candle Lighting")
              .accessibilityHint("Receive notification before candle lighting time.")
              
              Text("Receive notification before candle lighting time.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
              
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
                .accessibilityLabel("Notification Time")
                .accessibilityHint("Choose how many minutes before candle lighting to receive notification")
              }
            }
          }
          
          Section {
            Button("Credits") {
              showCredits = true
            }
            .foregroundStyle(Color(uiColor: .label))
            
            Button("Send Feedback") {
              if let url = URL(string: "mailto:hey@guytepper.com") {
                UIApplication.shared.open(url)
              }
            }
            .foregroundStyle(Color(uiColor: .label))
            
            Button("Rate Shabbat Times") {
              if let url = URL(string: "https://apps.apple.com/app/shabbat-candle-times/id6741048381?action=write-review") {
                UIApplication.shared.open(url)
              }
            }
            .foregroundStyle(Color(uiColor: .label))
            
            ShareLink(
              item: URL(string: "https://apps.apple.com/app/shabbat-candle-times/id6741048381")!,
              subject: Text("Shabbat Times App"),
            ) {
              Text("Share App")
            }
            .foregroundStyle(Color(uiColor: .label))
          } footer: {
            HStack {
              Spacer()
              Text("v\(appVersion)")
                .font(.caption)
                .foregroundStyle(.secondary)
              Spacer()
            }
            .accessibilityLabel("App Version: \(appVersion)")
            .padding(.top, 8)
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
