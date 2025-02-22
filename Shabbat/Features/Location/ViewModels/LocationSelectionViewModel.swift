import SwiftUI
import MapKit
import OSLog

@Observable
final class LocationSelectionViewModel: NSObject {
  private var searchCompleter: MKLocalSearchCompleter
  var searchText = ""
  var cities: [City] = []
  var searchCompletions: [MKLocalSearchCompletion] = []
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
  
  func getCoordinatesForCity(_ searchResult: MKLocalSearchCompletion) async throws -> CLLocationCoordinate2D {
    let searchRequest = MKLocalSearch.Request()
    searchRequest.naturalLanguageQuery = "\(searchResult.title), \(searchResult.subtitle)"
    let search = MKLocalSearch(request: searchRequest)
    let response = try await search.start()
    
    guard let coordinate = response.mapItems.first?.placemark.coordinate else {
      throw NSError(domain: "LocationSearch", code: 1, userInfo: [NSLocalizedDescriptionKey: "No coordinates found"])
    }
    
    return coordinate
  }

}

extension LocationSelectionViewModel: MKLocalSearchCompleterDelegate {
  func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    Task { @MainActor in
      searchCompletions = completer.results
      cities = completer.results.map { result in
        City(
          name: result.title,
          country: result.subtitle,
          coordinate: CLLocationCoordinate2D() // Placeholder until we perform the coordinate search
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
