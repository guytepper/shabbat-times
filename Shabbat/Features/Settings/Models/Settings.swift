import SwiftData
import Foundation

@Model
class Settings {
  @Attribute(.unique) var id: UUID = UUID()
  var finishedOnboarding: Bool = false
  var morningNotification: Bool = false
  var candleLightningNotification: Bool = false
  var candleLightingNotificationMinutes: Int = 30
  var shabbatEndNotification: Bool = false
  var shabbatEndNotificationMinutes: Int = 10
  var candleLightingMinutesBeforeSunset: Int = 20
  var hasCustomizedCandleLightingMinutes: Bool = false
  var showSunsetTime: Bool = false
  
  init() {
    // Empty initializer is required by @Model
  }
}
