import MapKit
import SwiftData

@Model
class City: Identifiable, Hashable {
  var id: UUID
  var name: String
  var country: String
  var latitude: Double
  var longitude: Double
  
  var coordinate: CLLocationCoordinate2D {
    get { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
    set {
      latitude = newValue.latitude
      longitude = newValue.longitude
    }
  }
  
  init(id: UUID = UUID(), name: String, country: String, coordinate: CLLocationCoordinate2D) {
    self.id = id
    self.name = name
    self.country = country
    self.latitude = coordinate.latitude
    self.longitude = coordinate.longitude
  }
  
  static func == (lhs: City, rhs: City) -> Bool {
    lhs.id == rhs.id
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
