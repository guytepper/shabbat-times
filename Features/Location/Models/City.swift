import MapKit

struct City: Identifiable, Hashable {
  let id = UUID()
  let name: String
  let title: String
  let subtitle: String
  let coordinate: CLLocationCoordinate2D
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  static func == (lhs: City, rhs: City) -> Bool {
    lhs.id == rhs.id
  }
}
