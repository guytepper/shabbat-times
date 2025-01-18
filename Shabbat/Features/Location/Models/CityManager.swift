import SwiftUI
import SwiftData
import MapKit

@Observable
class CityManager {
  private var modelContext: ModelContext

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  func saveCity(name: String, country: String, coordinate: CLLocationCoordinate2D) {
    // Delete existing cities first (since we only want to store one)
    deleteAllCities()

    // Create and save new city
    let city = City(name: name, country: country, coordinate: coordinate)
    modelContext.insert(city)

    do {
      try modelContext.save()
    } catch {
      print("Error saving city: \(error.localizedDescription)")
    }
  }

  func getCurrentCity() -> City? {
    let descriptor = FetchDescriptor<City>(sortBy: [SortDescriptor(\.name, order: .reverse)])

    do {
      let cities = try modelContext.fetch(descriptor)
      return cities.first
    } catch {
      print("Error fetching city: \(error.localizedDescription)")
      return nil
    }
  }

  private func deleteAllCities() {
    let descriptor = FetchDescriptor<City>()

    do {
      let cities = try modelContext.fetch(descriptor)
      cities.forEach { modelContext.delete($0) }
      try modelContext.save()
    } catch {
      print("Error deleting cities: \(error.localizedDescription)")
    }
  }
}
