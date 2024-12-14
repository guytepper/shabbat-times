import SwiftUI

struct BottomBar: View {
  var body: some View {
    // Settings Button
    HStack {
      Button(action: {
      }) {
        Image(systemName: "gear")
          .font(.title2)
          .foregroundColor(.white)
      }
      
      Spacer()
      
      // Location Button
      Button(action: {
      }) {
        HStack(spacing: 4) {
          Image(systemName: "location.fill")
            .font(.body)
          Text("New York")
            .fontDesign(.rounded)
        }
        .foregroundColor(.white)
      }
      
      Spacer()
      
      // Menu Button
      Button(action: {
      }) {
        Image(systemName: "line.3.horizontal")
          .font(.title2)
          .foregroundColor(.white)
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 16)
  }
}
