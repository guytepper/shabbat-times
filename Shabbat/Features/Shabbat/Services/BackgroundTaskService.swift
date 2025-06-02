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
    
    let container = try! ModelContainer(for: City.self, Settings.self)
    let modelContext = ModelContext(container)
    
    // Get the current selected city
    let cityManager = CityManager(modelContext: modelContext)
    guard let city = cityManager.getCurrentCity() else {
      task.setTaskCompleted(success: false)
      return
    }
    
    let settingsManager = SettingsManager(modelContext: modelContext)
    let morningNotification = settingsManager.settings.morningNotification
    let candleLightingNotification = settingsManager.settings.candleLightningNotification
    
    // If both notifications are disabled, don't proceed
    if morningNotification == false && candleLightingNotification == false {
      print("Cancelled notification scheduling - all notifications disabled")
      task.setTaskCompleted(success: true)
      return
    }
    
    Task {
      // Fetch the upcoming Shabbat Times from the API
      await shabbatService.fetchShabbatTimes(for: city)
      
      if let candleLighting = shabbatService.candleLighting?.formattedDate(timeZone: shabbatService.timeZone),
         let havdalah = shabbatService.havdalah?.formattedDate(timeZone: shabbatService.timeZone) {
        
        // Remove all pending notifications
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        // Set up morning reminder notification if enabled
        if morningNotification {
          await scheduleMorningNotification(for: candleLighting)
        }
        
        // Set up candle lighting reminder notification if enabled
        if candleLightingNotification {
          let minutesBefore = settingsManager.settings.candleLightingNotificationMinutes
          
          await scheduleCandleLightingNotification(
            for: candleLighting,
            minutesBefore: minutesBefore
          )
        }
        
        let dayAfterHavdalah = Calendar.current.date(
          byAdding: .day,
          value: 1,
          to: havdalah
        ) ?? havdalah
        
        // Schedule the next time a notification should be prepared
        scheduleAppRefresh(dayAfterHavdalah)
      }
      
      task.setTaskCompleted(success: true)
    }
  }
  
  /// Schedules the morning notification for Shabbat
  private func scheduleMorningNotification(for candleLightingTime: Date) async {
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
    
    // Use the city's timezone from the API response
    if let cityTimeZone = shabbatService.timeZone {
      formatter.timeZone = TimeZone(identifier: cityTimeZone)
    }
    
    let timeString = formatter.string(from: candleLightingTime)
    
    let timezoneInfo = getTimezoneInfo()
    
    let greeting = getGreeting()
    content.body = String(localized: "Candle lighting today at \(timeString)\(timezoneInfo). \(greeting)")
    
    // Create trigger using the system calendar and timezone
    let calendar = Calendar.current
    let notificationDate = calendar.date(
      bySettingHour: 9,  // 9 AM
      minute: 0,
      second: 0,
      of: candleLightingTime
    ) ?? candleLightingTime
    
    let components = calendar.dateComponents(
      [.year, .month, .day, .hour, .minute, .second],
      from: notificationDate
    )
    
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    
    let request = UNNotificationRequest(
      identifier: "morning-notification-\(UUID().uuidString)",
      content: content,
      trigger: trigger
    )
    
    do {
      try await center.add(request)
      print("Scheduled morning notification successfully for 9 AM")
      
      // For debugging purposes
      let pending = await center.pendingNotificationRequests()
      print("Pending notifications: \(pending.count)")
      pending.forEach { print($0.identifier) }
    } catch {
      print("Error scheduling morning notification: \(error)")
    }
  }
  
  /// Schedules a notification X minutes before candle lighting time
  private func scheduleCandleLightingNotification(for candleLightingTime: Date, minutesBefore: Int) async {
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
    
    // Use the city's timezone from the API response
    if let cityTimeZone = shabbatService.timeZone {
      formatter.timeZone = TimeZone(identifier: cityTimeZone)
    }
    
    let timeString = formatter.string(from: candleLightingTime)
    
    let timezoneInfo = getTimezoneInfo()
    content.body = String(localized: "Candle lighting is in \(minutesBefore) minutes, at \(timeString)\(timezoneInfo).")
    
    let calendar = Calendar.current
    
    guard let notificationTime = calendar.date(
      byAdding: .minute,
      value: -minutesBefore,
      to: candleLightingTime
    ) else {
      print("Error: Failed to calculate notification time")
      return
    }
    
    let components = calendar.dateComponents(
      [.year, .month, .day, .hour, .minute, .second],
      from: notificationTime
    )
    
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    
    let request = UNNotificationRequest(
      identifier: "candle-lighting-notification-\(UUID().uuidString)",
      content: content,
      trigger: trigger
    )
    
    do {
      try await center.add(request)
      
      // For debugging purposes
      let pending = await center.pendingNotificationRequests()
      print("Pending notifications: \(pending.count)")
    } catch {
      print("Error scheduling candle lighting notification: \(error)")
    }
  }
  
  /// Schedules the next time the task should run
  func scheduleAppRefresh(_ date: Date) {
    let request = BGAppRefreshTaskRequest(identifier: "com.guytepper.Shabbat.refreshShabbatTimes")
    
    request.earliestBeginDate = date
    // request.earliestBeginDate = Date(timeIntervalSinceNow: 10) // 10 secs for testing
    
    do {
      try BGTaskScheduler.shared.submit(request)
      print("Registered app refresh.")
    } catch {
      print("Could not schedule app refresh: \(error)")
    }
  }
  
  // MARK: - Helper Methods
  
  /// Returns appropriate greeting based on whether there's a holiday
  private func getGreeting() -> String {
    if shabbatService.holiday != nil {
      return String(localized: "Happy holidays!")
    } else {
      return String(localized: "Shabbat Shalom!")
    }
  }
  
  /// Returns timezone clarification text if user's timezone differs from city's timezone
  private func getTimezoneInfo() -> String {
    let needsTimezoneClarity: Bool = {
      guard let cityTimeZone = shabbatService.timeZone,
            let cityTZ = TimeZone(identifier: cityTimeZone) else { return false }
      let userTZ = TimeZone.current
      let now = Date()
      return cityTZ.secondsFromGMT(for: now) != userTZ.secondsFromGMT(for: now)
    }()
    
    if needsTimezoneClarity {
      let cityName = String(shabbatService.timeZone?.split(separator: "/").last ?? "")
        .replacingOccurrences(of: "_", with: " ")
      return String(localized: " (\(cityName) timezone)")
    } else {
      return ""
    }
  }
}
