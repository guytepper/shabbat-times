import SwiftUI

struct ParashaView: View {
  var body: some View {
    Text("Parasha View")
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
