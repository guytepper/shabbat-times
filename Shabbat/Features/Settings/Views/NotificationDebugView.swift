import SwiftUI
import UserNotifications

struct NotificationDebugView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var pendingNotifications: [UNNotificationRequest] = []
  @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
  @State private var lastSchedulingDate: Date?
  
  private let backgroundTaskService = BackgroundTaskService.shared
  
  func fetchDebugInfo() async {
    let center = UNUserNotificationCenter.current()
    pendingNotifications = await center.pendingNotificationRequests()
      .filter { $0.identifier.contains("morning") || $0.identifier.contains("candle") }
    
    let settings = await center.notificationSettings()
    notificationStatus = settings.authorizationStatus
    
    lastSchedulingDate = UserDefaults.standard.object(forKey: "lastNotificationScheduling") as? Date
  }
  
  func sendTestNotification() {
    let content = UNMutableNotificationContent()
    content.title = String(localized: "Test Notification")
    content.body = String(localized: "If you see this, notifications are working.")
    content.sound = .default
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("Error sending test notification: \(error)")
      }
    }
  }
  
  var statusText: String {
    switch notificationStatus {
    case .authorized: return "Authorized"
    case .denied: return "Denied"
    case .notDetermined: return "Not Determined"
    case .provisional: return "Provisional"
    case .ephemeral: return "Ephemeral"
    @unknown default: return "Unknown"
    }
  }
  
  var body: some View {
    Section("Debug") {
      Group {
        VStack(alignment: .leading, spacing: 8) {
          Text("Notification Status: \(statusText)")
          
          if let date = lastSchedulingDate {
            Text("Last schedule: \(date.formatted(date: .abbreviated, time: .shortened))")
          } else {
            Text("Never scheduled")
          }
          
          Text("Pending Shabbat alerts: \(pendingNotifications.count)")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        
        Button("Manually Schedule Notifications") {
          Task {
            await backgroundTaskService.scheduleNotificationsInForeground(context: modelContext)
            await fetchDebugInfo()
          }
        }
        
        Button("Send Test Notification Now") {
          sendTestNotification()
        }
      }
      
      if !pendingNotifications.isEmpty {
        DisclosureGroup("View Pending Notifications (\(pendingNotifications.count))") {
          ForEach(pendingNotifications, id: \.identifier) { notification in
            VStack(alignment: .leading, spacing: 4) {
              if let trigger = notification.trigger as? UNCalendarNotificationTrigger,
                 let nextDate = trigger.nextTriggerDate() {
                Text(nextDate.formatted(date: .abbreviated, time: .shortened))
                  .fontWeight(.bold)
              }
              
              Text(notification.content.body)
            }
            .font(.caption)
            .padding(.vertical, 4)
          }
        }
      }
    }
    .task {
      await fetchDebugInfo()
    }
  }
}
