import SwiftUI

struct ParashaModalView: View {
  let parasha: ParashaInfo?
  let isLoading: Bool
  let dismiss: () -> Void
  
  var body: some View {
    NavigationStack {
      ScrollView {
        if isLoading {
          ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let parasha = self.parasha {
          VStack(alignment: .leading, spacing: 24) {
            Text(parasha.name)
              .font(.system(.title, design: .serif))
              .fontWeight(.bold)
            
            Text(parasha.description)
              .font(.body)
          }
          .padding()
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done", action: dismiss)
        }
      }
    }
  }
} 
