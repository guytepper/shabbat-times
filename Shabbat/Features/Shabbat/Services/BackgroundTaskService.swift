import BackgroundTasks
import SwiftData
import UserNotifications

class BackgroundTaskService {
  static let shared = BackgroundTaskService()
  private let shabbatService = ShabbatService()
  
  private init() {}
  
  func registerBackgroundTasks() {
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: "com.guytepper.Shabbat.refreshShabbatTimes",
      using: nil
    ) { task in
      print("Background task started:", task)
      self.handleAppRefresh(task: task as! BGAppRefreshTask)
    }
  }
  
  func scheduleAppRefresh(_ date: Date) {
    let request = BGAppRefreshTaskRequest(identifier: "com.guytepper.Shabbat.refreshShabbatTimes")
    
    // Schedule refresh for 24 hours after the end date
    // request.earliestBeginDate = date
    request.earliestBeginDate = Date(timeIntervalSinceNow: 10) // 10 secs
    
    do {
      try BGTaskScheduler.shared.submit(request)
      print("Regitered app refresh.")
    } catch {
      print("Could not schedule app refresh: \(error)")
    }
  }
  
  private func handleAppRefresh(task: BGAppRefreshTask) {
    print("app refresh! wooho!")
    // Create a task to fetch the next Shabbat times
    task.expirationHandler = {
      task.setTaskCompleted(success: false)
    }

    let cityManager = CityManager(modelContext: ModelContext(try! ModelContainer(for: City.self)))
    guard let city = cityManager.getCurrentCity() else {
      task.setTaskCompleted(success: false)
      return
    }
    
    Task {
//      await shabbatService.fetchShabbatTimes(for: city)
//      
//      if let candleLighting = shabbatService.candleLighting?.formattedDate(timeZone: shabbatService.timeZone),
//         let havdalah = shabbatService.havdalah?.formattedDate(timeZone: shabbatService.timeZone) {
//        await scheduleNotification(for: candleLighting)
//        
//        let dayAfterHavdalah = Calendar.current.date(
//          byAdding: .day,
//          value: 1,
//          to: havdalah
//        ) ?? havdalah
//        scheduleAppRefresh(dayAfterHavdalah)
//      }
      let testDate = Date().addingTimeInterval(60) // 1 minute in the future
      await scheduleNotification(for: testDate)
      task.setTaskCompleted(success: true)
    }
  }
  
  private func scheduleNotification(for candleLightingTime: Date) async {
    let center = UNUserNotificationCenter.current()
    
    // First, check if we have notification permissions
    let settings = await center.notificationSettings()
    guard settings.authorizationStatus == .authorized else {
        print("Notifications not authorized")
        return
    }
    
    // Create notification content
    let content = UNMutableNotificationContent()
    content.title = String(localized: "Shabbat Shalom!")
    
    // Format the time using the correct timezone
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.timeZone = Calendar.current.timeZone // Ensure correct timezone
    let timeString = formatter.string(from: candleLightingTime)
    content.body = String(localized: "Candle lightning today at \(timeString)")
    
    // Create trigger using the system calendar and timezone
    var calendar = Calendar.current
    calendar.timeZone = Calendar.current.timeZone

    let components = calendar.dateComponents(
      [.year, .month, .day, .hour, .minute, .second],
      from: candleLightingTime
    )
    
    // Debug prints
//    print("Scheduling notification for: \(triggerDate)")
    print("Components: \(components)")
    
    let trigger: UNCalendarNotificationTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    
    // Create request with unique identifier
    let request = UNNotificationRequest(
        identifier: UUID().uuidString, // More unique identifier
        content: content,
        trigger: trigger
    )
    
    // Schedule notification
    do {
        try await center.add(request)
        print("Scheduled notification successfully")
        
        // Debug: List all pending notifications
        let pending = await center.pendingNotificationRequests()
        print("Pending notifications: \(pending.count)")
        pending.forEach { print($0.identifier) }
    } catch {
        print("Error scheduling notification: \(error)")
    }
  }
}
