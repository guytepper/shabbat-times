import SwiftUI
import SwiftData

struct BottomBar: View {
  let cityName: String
  let onCitySelected: (City) -> Void
  @State private var showLocationPicker = false
  
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
        showLocationPicker = true
      }) {
        HStack(spacing: 4) {
          Image(systemName: "location.fill")
            .font(.body)
          Text(cityName)
            .fontDesign(.rounded)
        }
        .foregroundColor(.white)
      }
      .fullScreenCover(isPresented: $showLocationPicker) {
        LocationSelectionView { city in
          onCitySelected(city)
        }
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
