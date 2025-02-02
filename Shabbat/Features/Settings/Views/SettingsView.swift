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
    NavigationView {
      List {
        Section(header: Text("Display Options")) {
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
      .background(gradientBackground)
      .scrollContentBackground(.hidden)
    }
  }
  
  var gradientBackground: some ShapeStyle {
    return LinearGradient(
      colors: colorScheme == .dark ? [
        .hsl(h: 48, s: 0, l: 2),    // Very dark gray
        .hsl(h: 48, s: 30, l: 10)   // Dark warm brown
      ] : [
        .hsl(h: 0, s: 0, l: 100),   // White
        .hsl(h: 48, s: 55, l: 84)   // Light warm beige
      ],
      startPoint: .top,
      endPoint: .bottom
    )
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
