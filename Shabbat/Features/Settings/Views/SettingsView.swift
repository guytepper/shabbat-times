import SwiftUI
import SwiftData

struct SettingsView: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.modelContext) private var modelContext
  @State private var settingsManager: SettingsManager
  
  init(modelContext: ModelContext) {
    self.settingsManager = SettingsManager(modelContext: modelContext)
  }
  
  var settings: Settings {
    settingsManager.settings
  }
  
  var body: some View {
    NavigationStack {
      List {
        Section {
          VStack(alignment: .leading, spacing: 6) {
            Toggle("Morning Notification", isOn: Binding(
              get: { settings.morningNotification },
              set: { newValue in
                settingsManager.updateSettings { settings in
                  settings.morningNotification = newValue
                }
              }
            ))
            
            Text("Friday morning shabbat times notification.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          
          VStack(alignment: .leading, spacing: 6) {
            Picker("Parasha Language", selection: Binding(
              get: { settings.parashaLanguage },
              set: { newValue in
                settingsManager.updateSettings { settings in
                  settings.parashaLanguage = newValue
                }})) {
                  Text("English").tag("en")
                  Text("Hebrew").tag("he")
                  Text("Bilingual").tag("bi")
                }
            
            Text("Reading the Parasha on the Sefaria website will be in the chosen language.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      .navigationTitle("Settings")
      .background(Color.gradientBackground(for: colorScheme))
      .scrollContentBackground(.hidden)
    }
  }
}

#Preview {
  let container = try! ModelContainer(
    for: Settings.self,
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
  )
  
  SettingsView(modelContext: container.mainContext)
    .modelContainer(container)
}
