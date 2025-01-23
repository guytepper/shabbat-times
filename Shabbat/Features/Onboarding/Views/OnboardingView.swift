
import SwiftUI
import SwiftData
struct OnboardingView: View {
  @StateObject private var locationManager = LocationManager()
  @State private var showLocationPicker = false
  
  @Environment(\.modelContext) private var modelContext
  private var cityManager: CityManager {
    CityManager(modelContext: modelContext)
  }
  
  var body: some View {
    VStack(spacing: 32) {
      headerView
      selectCityButton
    }
    .padding()
    .frame(maxHeight: .infinity)
    .background(Color(.systemBackground))
    .padding(.bottom, 32)
  }
  
  private var headerView: some View {
    VStack(spacing: 16) {
      Text("🕯️")
        .font(.system(size: 60))
        .foregroundColor(.blue)
      
      Text("Shabbat Shalom!")
        .font(.largeTitle)
        .fontWeight(.bold)
      
      Text("Choose your city to get Shabbat times for your location.")
        .font(.body)
        .multilineTextAlignment(.center)
    }
  }
  
  private var selectCityButton: some View {
    Button {
      showLocationPicker = true
    } label: {
      HStack {
        //       Image(systemName: "house")
        Text("Select City")
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(Color.blue)
      .foregroundColor(.white)
      .cornerRadius(10)
    }
    .fullScreenCover(isPresented: $showLocationPicker) {
      LocationSelectionView { city in
        cityManager.saveCity(
          name: city.name,
          country: city.country,
          coordinate: city.coordinate
        )
      }
    }
    
  }
}

#Preview {
  OnboardingView()
    .modelContainer(for: City.self, inMemory: true)
}
