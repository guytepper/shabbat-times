import SwiftUI

struct ParashaButton: View {
  let parasahName: String
  let action: () -> Void
  
  var isHebrewLocale: Bool {
    Locale.current.language.languageCode?.identifier == "he"
  }
  
  var body: some View {
    Button(action: action) {
      VStack(spacing: 6) {
        Text("parashat hashavua")
          .fontWidth(.expanded)
        
        Text(parasahName)
          .font(.system(isHebrewLocale ? .title2 : .title3, design: .serif))
          .fontWeight(.bold)
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(.ultraThinMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    .buttonStyle(.plain)
  }
}
