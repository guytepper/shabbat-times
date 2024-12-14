import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  @Published var location: CLLocation?
  @Published var error: Error?
  
  override init() {
    super.init()
    manager.delegate = self
  }
  
  func requestOneTimeLocation() {
    // This only requests permission for when-in-use
    manager.requestWhenInUseAuthorization()
    // This requests a single location update
    manager.requestLocation()
    // We're not calling startUpdatingLocation(), so it won't continuously track
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if let location = locations.first {
      self.location = location
      // Important: The manager will automatically stop after getting this single location
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    self.error = error
  }
}
