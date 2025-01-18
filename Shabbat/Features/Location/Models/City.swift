import MapKit
import SwiftData

@Model
struct City: Identifiable, Hashable {
  var id = UUID()
  var name: String
  var country: String
  var coordinate: CLLocationCoordinate2D

  init(name: String, country: String, coordinate: CLLocationCoordinate2D) {
    self.name = name
    self.country = country
    self.coordinate = coordinate
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func == (lhs: City, rhs: City) -> Bool {
    lhs.id == rhs.id
  }
}
