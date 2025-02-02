import SwiftData
import Foundation

@Model
class Settings {
  @Attribute(.unique) var id: UUID = UUID()
  var parashaLanguage: String
  
  init(parashaLanguage: String = "en") {
    self.parashaLanguage = parashaLanguage
  }
}
