import SwiftData
import Foundation

@Model
class Settings {
  @Attribute(.unique) var id: UUID = UUID()
  var parashaLanguage: String = "en"
  var finishedOnboarding: Bool = false
  var morningNotification: Bool = false
  var candleLightningNotification: Bool = false
  var candleLightingNotificationMinutes: Int = 30
  
  init(parashaLanguage: String = "en") {
    self.parashaLanguage = parashaLanguage
  }
}
