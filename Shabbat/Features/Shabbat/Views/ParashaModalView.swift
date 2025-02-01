import SwiftUI

struct ParashaModalView: View {
  let parasha: ParashaInfo?
  let isLoading: Bool
  let dismiss: () -> Void
  
  var isHebrewLocale: Bool {
    Locale.current.language.languageCode?.identifier == "he"
  }
  
  var body: some View {
    NavigationStack {
      ScrollView {
        if isLoading {
          ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let parasha = self.parasha {
          VStack(alignment: .leading) {
            Text(parasha.name)
              .font(isHebrewLocale ? .largeTitle : .title)
              .fontDesign(isHebrewLocale ? .rounded : .serif)
              .fontWeight(.bold)
              .padding(.bottom, 8)
            
            Text(parasha.description)
              .lineSpacing(5)
          }
          .padding(.horizontal)
        }
      }
      .background(.thinMaterial)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Close", action: dismiss)
        }
      }
    }
  }
}
