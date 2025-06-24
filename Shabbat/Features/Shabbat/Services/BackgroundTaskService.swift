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
  
  // MARK: - Constants
  private let backgroundTaskIdentifier = "com.guytepper.Shabbat.refreshShabbatTimes"
  private let weeksToScheduleInAdvance = 3
  private let maxNotificationsAllowed = 64 // iOS limit
  
  // MARK: - Properties
  private let shabbatService = ShabbatService()
  private var lastSchedulingDate: Date {
    get { UserDefaults.standard.object(forKey: "lastNotificationScheduling") as? Date ?? Date.distantPast }
    set { UserDefaults.standard.set(newValue, forKey: "lastNotificationScheduling") }
  }
  
  func registerBackgroundTasks() {
    // Register a task with identifier
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: backgroundTaskIdentifier,
      using: nil
    ) { task in
      self.handleAppRefresh(task: task as! BGAppRefreshTask)
    }
  }
  
  // MARK: - Public Methods
  
  /// Schedule notifications when app is in foreground (more reliable)
  func scheduleNotificationsInForeground(context: ModelContext? = nil) async {
    await scheduleNotifications(isBackground: false, context: context)
  }

  // MARK: - Background Task Handling
  
  private func handleAppRefresh(task: BGAppRefreshTask) {
    task.expirationHandler = {
      print("Background task expired")
      task.setTaskCompleted(success: false)
    }
    
    let container: ModelContainer
    do {
      container = try ModelContainer(for: City.self, Settings.self)
    } catch {
      print("Failed to create ModelContainer: \(error)")
      task.setTaskCompleted(success: false)
      return
    }
    
    let modelContext = ModelContext(container)
    
    Task {
      await scheduleNotifications(isBackground: true, context: modelContext)
      
      // Schedule multiple redundant background tasks
      scheduleRedundantBackgroundTasks()
      
      task.setTaskCompleted(success: true)
    }
  }
  
  // MARK: - Core Scheduling Logic
  
  private func scheduleNotifications(isBackground: Bool, context: ModelContext?) async {
    let modelContext = context ?? {
      do {
        let container = try ModelContainer(for: City.self, Settings.self)
        return ModelContext(container)
      } catch {
        print("Failed to create ModelContext: \(error)")
        return nil
      }
    }()
    
    guard let modelContext = modelContext else {
      print("No ModelContext available")
      return
    }
    
    // Get the current selected city
    let cityManager = CityManager(modelContext: modelContext)
    guard let city = cityManager.getCurrentCity() else {
      print("No city selected")
      return
    }
    
    let settingsManager = SettingsManager(modelContext: modelContext)
    let settings = settingsManager.settings
    
    // If both notifications are disabled, don't proceed
    if !settings.morningNotification && !settings.candleLightningNotification {
      print("All notifications disabled")
      return
    }
    
    // Check notification permissions
    let center = UNUserNotificationCenter.current()
    let notificationSettings = await center.notificationSettings()
    guard notificationSettings.authorizationStatus == .authorized else {
      print("Notifications not authorized")
      return
    }
    
    do {
      // Fetch multiple weeks of Shabbat times
      let shabbatDates = try await fetchMultipleWeeksShabbatTimes(
        city: city,
        candleLightingMinutes: settings.candleLightingMinutesBeforeSunset,
        weeks: weeksToScheduleInAdvance
      )
      
      // Only clear notifications that we're about to replace
      await clearOldShabbatNotifications()
      
      // Schedule notifications for all fetched weeks
      var notificationsScheduled = 0
      
      for (week, shabbatData) in shabbatDates.enumerated() {
        if notificationsScheduled >= maxNotificationsAllowed - 10 { // Leave some buffer
          print("Approaching notification limit, stopping at week \(week)")
          break
        }
        
        if settings.morningNotification {
          await scheduleMorningNotification(
            for: shabbatData.candleLighting,
            timeZone: shabbatData.timeZone,
            holiday: shabbatData.holiday,
            week: week
          )
          notificationsScheduled += 1
        }
        
        if settings.candleLightningNotification {
          let minutesBefore = settings.candleLightingNotificationMinutes
          await scheduleCandleLightingNotification(
            for: shabbatData.candleLighting,
            minutesBefore: minutesBefore,
            timeZone: shabbatData.timeZone,
            holiday: shabbatData.holiday,
            week: week
          )
          notificationsScheduled += 1
        }
      }
      
      print("Successfully scheduled \(notificationsScheduled) notifications for \(shabbatDates.count) weeks")
      lastSchedulingDate = Date()
      
    } catch {
      print("Error scheduling notifications: \(error)")
    }
  }
  
  // MARK: - Multi-Week Fetching
  
  private struct ShabbatWeekData {
    let candleLighting: Date
    let havdalah: Date
    let timeZone: String
    let holiday: String?
  }
  
  private func fetchMultipleWeeksShabbatTimes(
    city: City,
    candleLightingMinutes: Int,
    weeks: Int
  ) async throws -> [ShabbatWeekData] {
    var results: [ShabbatWeekData] = []
    let calendar = Calendar.current
    
    for week in 0..<weeks {
      // Calculate the target Friday for this week
      let startDate = calendar.date(byAdding: .weekOfYear, value: week, to: Date()) ?? Date()
      let targetFriday = getNextFriday(from: startDate)
      
      // Create a temporary ShabbatService for each week
      let weeklyShabbatService = ShabbatService()
      
      // Use a custom API call that can fetch data for specific dates
      let shabbatData = try await fetchShabbatTimesForSpecificWeek(
        service: weeklyShabbatService,
        city: city,
        targetDate: targetFriday,
        candleLightingMinutes: candleLightingMinutes
      )
      
      if let data = shabbatData {
        results.append(data)
      }
    }
    
    return results
  }
  
  private func fetchShabbatTimesForSpecificWeek(
    service: ShabbatService,
    city: City,
    targetDate: Date,
    candleLightingMinutes: Int
  ) async throws -> ShabbatWeekData? {
    await service.fetchShabbatTimes(
      for: city,
      candleLightingMinutes: candleLightingMinutes,
      forDate: targetDate
    )
    
    guard let candleLighting = service.candleLighting?.formattedDate(timeZone: service.timeZone),
          let havdalah = service.havdalah?.formattedDate(timeZone: service.timeZone),
          let timeZone = service.timeZone else {
      return nil
    }
    
    return ShabbatWeekData(
      candleLighting: candleLighting,
      havdalah: havdalah,
      timeZone: timeZone,
      holiday: service.holiday?.title
    )
  }
  
  private func getNextFriday(from date: Date) -> Date {
    let calendar = Calendar.current
    let weekday = calendar.component(.weekday, from: date)
    let daysUntilFriday = (6 - weekday + 7) % 7
    let adjustedDays = daysUntilFriday == 0 ? 0 : daysUntilFriday
    return calendar.date(byAdding: .day, value: adjustedDays, to: date) ?? date
  }
  
  // MARK: - Notification Scheduling
  
  private func clearOldShabbatNotifications() async {
    let center = UNUserNotificationCenter.current()
    let pendingNotifications = await center.pendingNotificationRequests()
    
    // Only remove our Shabbat notifications, not all notifications
    let shabbatNotificationIds = pendingNotifications
      .filter { $0.identifier.contains("morning-notification") || $0.identifier.contains("candle-lighting-notification") }
      .map { $0.identifier }
    
    center.removePendingNotificationRequests(withIdentifiers: shabbatNotificationIds)
    print("Cleared \(shabbatNotificationIds.count) old Shabbat notifications")
  }
  
  /// Schedules the morning notification for Shabbat
  private func scheduleMorningNotification(
    for candleLightingTime: Date,
    timeZone: String,
    holiday: String?,
    week: Int
  ) async {
    let center = UNUserNotificationCenter.current()
    
    // Create notification content
    let content = UNMutableNotificationContent()
    content.title = String(localized: "Shabbat Times")
    
    // Format the time using the correct timezone
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.timeZone = TimeZone(identifier: timeZone)
    
    let timeString = formatter.string(from: candleLightingTime)
    
    let timezoneInfo = getTimezoneInfo(for: timeZone)
    let greeting = getGreeting(for: holiday)
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
      identifier: "morning-notification-week\(week)-\(UUID().uuidString)",
      content: content,
      trigger: trigger
    )
    
    do {
      try await center.add(request)
      print("Scheduled morning notification for week \(week) at 9 AM on \(notificationDate)")
    } catch {
      print("Error scheduling morning notification for week \(week): \(error)")
    }
  }
  
  /// Schedules a notification X minutes before candle lighting time
  private func scheduleCandleLightingNotification(
    for candleLightingTime: Date,
    minutesBefore: Int,
    timeZone: String,
    holiday: String?,
    week: Int
  ) async {
    let center = UNUserNotificationCenter.current()
    
    // Create notification content
    let content = UNMutableNotificationContent()
    content.title = String(localized: "Shabbat Times")
    content.interruptionLevel = .timeSensitive
    content.relevanceScore = 1.0
    
    // Format the time using the correct timezone
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.timeZone = TimeZone(identifier: timeZone)
    
    let timeString = formatter.string(from: candleLightingTime)
    
    let timezoneInfo = getTimezoneInfo(for: timeZone)
    content.body = String(localized: "Candle lighting is in \(minutesBefore) minutes, at \(timeString)\(timezoneInfo).")
    
    let calendar = Calendar.current
    
    guard let notificationTime = calendar.date(
      byAdding: .minute,
      value: -minutesBefore,
      to: candleLightingTime
    ) else {
      print("Error: Failed to calculate notification time for week \(week)")
      return
    }
    
    let components = calendar.dateComponents(
      [.year, .month, .day, .hour, .minute, .second],
      from: notificationTime
    )
    
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    
    let request = UNNotificationRequest(
      identifier: "candle-lighting-notification-week\(week)-\(UUID().uuidString)",
      content: content,
      trigger: trigger
    )
    
    do {
      try await center.add(request)
      print("Scheduled candle lighting notification for week \(week) at \(notificationTime)")
    } catch {
      print("Error scheduling candle lighting notification for week \(week): \(error)")
    }
  }
  
  // MARK: - Background Task Scheduling
  
  /// Schedules multiple redundant background tasks to increase reliability
  private func scheduleRedundantBackgroundTasks() {
    let calendar = Calendar.current
    let now = Date()
    
    // Schedule primary task for next Sunday
    if let nextSunday = calendar.nextDate(after: now, matching: DateComponents(weekday: 1), matchingPolicy: .nextTime) {
      scheduleAppRefresh(nextSunday)
    }
    
    // Schedule backup task for Wednesday (mid-week)
    if let nextWednesday = calendar.nextDate(after: now, matching: DateComponents(weekday: 4), matchingPolicy: .nextTime) {
      scheduleAppRefresh(calendar.date(byAdding: .hour, value: 2, to: nextWednesday) ?? nextWednesday)
    }
    
    // Schedule another backup for Thursday morning
    if let nextThursday = calendar.nextDate(after: now, matching: DateComponents(hour: 9, weekday: 5), matchingPolicy: .nextTime) {
      scheduleAppRefresh(nextThursday)
    }
  }
  
  /// Schedules the next time the task should run
  func scheduleAppRefresh(_ date: Date) {
    let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
    
    request.earliestBeginDate = date
    // request.earliestBeginDate = Date(timeIntervalSinceNow: 10) // 10 secs for testing
    
    do {
      try BGTaskScheduler.shared.submit(request)
      print("Registered app refresh for \(date)")
    } catch {
      print("Could not schedule app refresh: \(error)")
    }
  }
  
  // MARK: - Helper Methods
  
  /// Returns appropriate greeting based on whether there's a holiday
  private func getGreeting(for holiday: String?) -> String {
    if holiday != nil {
      return String(localized: "Happy holidays!")
    } else {
      return String(localized: "Shabbat Shalom!")
    }
  }
  
  /// Returns timezone clarification text if user's timezone differs from city's timezone
  private func getTimezoneInfo(for cityTimeZone: String) -> String {
    guard let cityTZ = TimeZone(identifier: cityTimeZone) else { return "" }
    
    let userTZ = TimeZone.current
    let now = Date()
    let needsTimezoneClarity = cityTZ.secondsFromGMT(for: now) != userTZ.secondsFromGMT(for: now)
    
    if needsTimezoneClarity {
      let cityName = String(cityTimeZone.split(separator: "/").last ?? "")
        .replacingOccurrences(of: "_", with: " ")
      return String(localized: " (\(cityName) timezone)")
    } else {
      return ""
    }
  }
  
  // MARK: - Debug Methods
  
  #if DEBUG
  func printNotificationDebugInfo() async {
    let center = UNUserNotificationCenter.current()
    let pending = await center.pendingNotificationRequests()
    let shabbatNotifications = pending.filter { 
      $0.identifier.contains("morning-notification") || $0.identifier.contains("candle-lighting-notification") 
    }
    
    print("=== Notification Debug Info ===")
    print("Total pending notifications: \(pending.count)")
    print("Shabbat notifications: \(shabbatNotifications.count)")
    print("Last scheduling date: \(lastSchedulingDate)")
    
    for notification in shabbatNotifications.prefix(10) {
      if let trigger = notification.trigger as? UNCalendarNotificationTrigger,
         let nextDate = trigger.nextTriggerDate() {
        print("- \(notification.identifier): \(nextDate)")
      }
    }
    print("===============================")
  }
  #endif
}
