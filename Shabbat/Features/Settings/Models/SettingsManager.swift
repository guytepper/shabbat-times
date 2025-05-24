import SwiftData
import SwiftUI

@Observable
class SettingsManager {
  var settings: Settings
  private let modelContext: ModelContext
  
  init(modelContext: ModelContext) {
    self.modelContext = modelContext
    let descriptor = FetchDescriptor<Settings>()
    if let existingSettings = try? modelContext.fetch(descriptor).first {
      settings = existingSettings
    } else {
      let newSettings = Settings()
      modelContext.insert(newSettings)
      try? modelContext.save()
      settings = newSettings
    }
  }
  
  func updateSettings(_ update: (Settings) -> Void) {
    update(settings)
    try? modelContext.save()
  }
}
