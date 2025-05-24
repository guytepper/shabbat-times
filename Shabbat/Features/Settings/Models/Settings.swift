import SwiftData
import Foundation

@Model
class Settings {
  @Attribute(.unique) var id: UUID = UUID()
  var finishedOnboarding: Bool = false
  var morningNotification: Bool = false
  var candleLightningNotification: Bool = false
  var candleLightingNotificationMinutes: Int = 30
  
  init() {
    // Empty initializer is required by @Model
  }
}
