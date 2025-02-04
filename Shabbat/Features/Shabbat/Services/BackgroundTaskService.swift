import BackgroundTasks
import SwiftData
import UserNotifications

/*
  In order to debug the task, set up a breakpoint right after the call to:
      try BGTaskScheduler.shared.submit(request)
 
  and execute the following command in the debugger:
      e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.guytepper.Shabbat.refreshShabbatTimes"]
 
  The task will run once you resume the program execution.
*/

class BackgroundTaskService {
  static let shared = BackgroundTaskService()
  private let shabbatService = ShabbatService()
  
  func registerBackgroundTasks() {
    // Register a task with indentifier
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: "com.guytepper.Shabbat.refreshShabbatTimes",
      using: nil
    ) { task in
      self.handleAppRefresh(task: task as! BGAppRefreshTask)
    }
  }
  
  private func handleAppRefresh(task: BGAppRefreshTask) {
    task.expirationHandler = {
      task.setTaskCompleted(success: false)
    }
    
    // Get the current selected city
    let cityManager = CityManager(modelContext: ModelContext(try! ModelContainer(for: City.self)))
    guard let city = cityManager.getCurrentCity() else {
      task.setTaskCompleted(success: false)
      return
    }
    
    Task {
      // Fetch the upcoming Shabbat Times from the API
      await shabbatService.fetchShabbatTimes(for: city)
      
      if let candleLighting = shabbatService.candleLighting?.formattedDate(timeZone: shabbatService.timeZone),
         let havdalah = shabbatService.havdalah?.formattedDate(timeZone: shabbatService.timeZone) {
        
        // Set up morning reminder notification
        await scheduleNotification(for: candleLighting)
        
        let dayAfterHavdalah = Calendar.current.date(
          byAdding: .day,
          value: 1,
          to: havdalah
        ) ?? havdalah
        
        // Scheduale the next time a notification should be prepared
        scheduleAppRefresh(dayAfterHavdalah)
      }
      
      task.setTaskCompleted(success: true)
    }
  }
  
  /// Scheduales the time a Candle Lightning time notification should be sent to the user
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
    content.title = String(localized: "Shabbat Times")
    
    // Format the time using the correct timezone
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    let timeString = formatter.string(from: candleLightingTime)
    content.body = String(localized: "Candle lightning today at \(timeString). Shabbat Shalom!")
    
    // Create trigger using the system calendar and timezone
    // Test date for local development
    // let testDate = Date(timeIntervalSinceNow: 70)
    
    let calendar = Calendar.current
    let components = calendar.dateComponents(
      [.year, .month, .day, .hour, .minute, .second],
      from: candleLightingTime
    )
    
    print("Components: \(components)")
    
    let trigger: UNCalendarNotificationTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    
    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: trigger
    )
    
    do {
      try await center.add(request)
      print("Scheduled notification successfully")
      
      // For debugging purposes
      // let pending = await center.pendingNotificationRequests()
      // print("Pending notifications: \(pending.count)")
      // pending.forEach { print($0.identifier) }
    } catch {
      print("Error scheduling notification: \(error)")
    }
  }
  
  /// Scheduales the next time the task should run
  func scheduleAppRefresh(_ date: Date) {
    let request = BGAppRefreshTaskRequest(identifier: "com.guytepper.Shabbat.refreshShabbatTimes")
    
    // Schedule refresh for 24 hours after the end date
     request.earliestBeginDate = date
//    request.earliestBeginDate = Date(timeIntervalSinceNow: 10) // 10 secs
    
    do {
      try BGTaskScheduler.shared.submit(request)
      print("Regitered app refresh.")
    } catch {
      print("Could not schedule app refresh: \(error)")
    }
  }
  
}
