import SwiftUI

struct OnboardingViewWithLocation: View {
  @StateObject private var locationManager = LocationManager()
  @State private var isLocating = false
  @State private var showMainContent = false
  @State private var showError = false
  @State private var errorMessage = ""
  
  
  var body: some View {
    VStack(spacing: 32) {
      headerView
      locationButton
      
      Text("We'll only access your location once to determine your city for Shabbat times.")
        .font(.callout)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
    .padding()
    .frame(maxHeight: .infinity)
    .background(Color(.systemBackground))
    .alert("Error", isPresented: $showError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage)
    }
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
      
      Text("Let's set up your location to get accurate Shabbat times")
        .font(.body)
        .multilineTextAlignment(.center)
    }
  }
  
  private var locationButton: some View {
    Button {
      getLocation()
    } label: {
      HStack {
        if isLocating {
          ProgressView()
            .tint(.white)
        } else {
          Image(systemName: "location.fill")
          Text("Get Current Location")
        }
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(Color.blue)
      .foregroundColor(.white)
      .cornerRadius(10)
    }
    .disabled(isLocating)
  }
  
  private func getLocation() {
    isLocating = true
    locationManager.requestOneTimeLocation()
    
    // Check for location after a short delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      if let location = locationManager.location {
        // Here you would make your API call to Hebcal
        print("Location obtained: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        isLocating = false
        showMainContent = true
      } else if let error = locationManager.error {
        showError = true
        errorMessage = error.localizedDescription
        isLocating = false
      }
    }
  }
}

#Preview {
  OnboardingView()
    .modelContainer(for: City.self, inMemory: true)
}
