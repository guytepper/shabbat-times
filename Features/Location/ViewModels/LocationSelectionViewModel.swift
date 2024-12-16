import SwiftUI
import MapKit

@Observable
final class LocationSelectionViewModel: NSObject {
  private var searchCompleter: MKLocalSearchCompleter
  var searchText = ""
  var cities: [City] = []
  var isSearching = false
  var error: Error?
  
  override init() {
    searchCompleter = MKLocalSearchCompleter()
    super.init()
    searchCompleter.resultTypes = .address
    searchCompleter.delegate = self
  }
  
  func updateSearchText(_ text: String) {
    searchText = text
    
    guard !text.isEmpty else {
      cities = []
      return
    }
    
    searchCompleter.queryFragment = text
  }
}

extension LocationSelectionViewModel: MKLocalSearchCompleterDelegate {
  func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    Task { @MainActor in
      cities = completer.results.map { result in
        City(
          name: result.title,
          title: result.title,
          subtitle: result.subtitle,
          coordinate: CLLocationCoordinate2D(latitude: result., longitude: <#T##CLLocationDegrees#>) // Placeholder until we perform the search
        )
      }
    }
  }
  
  func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
    Task { @MainActor in
      self.error = error
      cities = []
    }
  }
}
