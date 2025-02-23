import SwiftUI
import UserNotifications

struct NotificationDebugView: View {
  @State private var pendingNotifications: [UNNotificationRequest] = []
  
  func fetchPendingNotifications() async {
    let center = UNUserNotificationCenter.current()
    pendingNotifications = await center.pendingNotificationRequests()
  }

  var body: some View {
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
    .task {
      #if DEBUG
      await fetchPendingNotifications()
      #endif
    }

  }
}
