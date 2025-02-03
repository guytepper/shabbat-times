import SwiftData
import Foundation

@Model
class Settings {
  @Attribute(.unique) var id: UUID = UUID()
  var parashaLanguage: String
  var finishedOnboarding: Bool
  
  init(parashaLanguage: String = "en", finishedOnboarding: Bool = false) {
    self.parashaLanguage = parashaLanguage
    self.finishedOnboarding = finishedOnboarding
  }
}
