import SwiftUI

struct ParashaView: View {
  /// TODO: just replace description with the hebrew one if the app language is hebrew
  @Environment(\.layoutDirection) var layoutDirection
  var parasha: ParashaInfo?
  var isLoading: Bool = true
  
  var description: String {
    if let parashaInfo = self.parasha {
      return layoutDirection == .rightToLeft ? parashaInfo.hebrewDescription : parashaInfo.description
    }
    
    return ""
  }

  var body: some View {
    ScrollView {
      if isLoading {
        ProgressView()
      } else if let parashaInfo = parasha {
        VStack(alignment: .leading, spacing: 8) {
          Text(parashaInfo.name)
            .font(.largeTitle)
            .fontWeight(.bold)
            .fontDesign(.serif)
          
          Text(description)
            .font(.title2)
            .lineSpacing(4.5)
        }
        .padding(.horizontal)
      }
    }
    .background(.amber)
  }
}

#Preview {
  NavigationView {
    ParashaView()
      .navigationTitle("Weekly Torah Portion")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            print("View Dismissed")
          }
        }
      }
  }
}
