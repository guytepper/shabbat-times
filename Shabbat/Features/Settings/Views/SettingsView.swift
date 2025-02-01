import SwiftUI

struct SettingsView: View {
  @Environment(\.colorScheme) private var colorScheme
  @AppStorage("parashaLanguage") private var parashaLanguage = "english"
  
  var body: some View {
    NavigationView {
      List {
        Section(header: Text("Display Options")) {
          VStack(alignment: .leading, spacing: 6) {
            Picker("Parasha Language", selection: $parashaLanguage) {
              Text("English").tag("english")
              Text("Hebrew").tag("hebrew")
              Text("Bilingual").tag("bilingual")
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
  SettingsView()
}
