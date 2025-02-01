import Foundation
import SwiftUI
import SwiftData

@Observable
class HomeViewModel {
  private var shabbatService = ShabbatService()
  private var parashaService = ParashaService()
  
  private var cityManager: CityManager?
  private let modelContext: ModelContext
  
  @MainActor var isLoading: Bool { shabbatService.isLoading }
  
  var error: Error? { shabbatService.error }
  
  var timeZone: TimeZone {
    TimeZone(identifier: shabbatService.timeZone ?? TimeZone.current.identifier) ?? .current
  }
  
  init(modelContext: ModelContext) {
    self.modelContext = modelContext
    self.cityManager = CityManager(modelContext: modelContext)
  }
  
  var cityName: String {
    cityManager?.getCurrentCity()?.name ?? ""
  }
  
  var candleLighting: Date? {
    shabbatService.candleLighting?.formattedDate(timeZone: shabbatService.timeZone)
  }
  
  var havdalah: Date? {
    shabbatService.havdalah?.formattedDate(timeZone: shabbatService.timeZone)
  }
  
  var parasha: ParashaInfo? {
    return parashaService.parasah
  }
  
  @MainActor var isParashaLoading: Bool {
    parashaService.isLoading
  }
  
  var parashaName: String {
    shabbatService.parasah?.title ?? ""
  }
  
  var isShabbat: Bool {
    guard let candleLighting = candleLighting,
          let havdalah = havdalah else {
      return false
    }
    
    let now = Date()
    return now >= candleLighting && now <= havdalah
  }
  
  func loadShabbatTimes() async {
    if let city = cityManager?.getCurrentCity() {
      await shabbatService.fetchShabbatTimes(for: city)
    }
  }
  
  func loadParasha() async throws {
    try await parashaService.fetchCurrentParasha()
  }
  
  func saveNewCity(city: City) {
    try? modelContext.delete(model: City.self)
    cityManager?.saveCity(
      name: city.name,
      country: city.country,
      coordinate: city.coordinate
    )
  }
  
  var nextShabbatDates: String? {
    let startDate = candleLighting ?? Date()
    let endDate = havdalah ?? Date()
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "d"
    dateFormatter.timeZone = timeZone
    
    let monthFormatter = DateFormatter()
    monthFormatter.dateFormat = "MMMM"
    monthFormatter.timeZone = timeZone
    
    let startDay = dateFormatter.string(from: startDate)
    let endDay = dateFormatter.string(from: endDate)
    
    // Handle cases where the start & end dates are on different months
    let startMonth = monthFormatter.string(from: startDate)
    let endMonth = monthFormatter.string(from: endDate)
    
    if startMonth == endMonth {
      return "\(startDay) - \(endDay) \(startMonth)"
    } else {
      return "\(startDay) \(startMonth) - \(endDay) \(endMonth)"
    }
  }
  var daysUntilShabbat: String? {
    guard let candleLighting = candleLighting else { return nil }
    
    let calendar = Calendar.current
    let now = Date()
    
    let components = calendar.dateComponents([.day], from: now, to: candleLighting)
    guard let days = components.day else { return nil }
    
    switch days {
    case 0:
      return String(localized: "today")
    case 1:
      return String(localized: "tomorrow")
    default:
      return String(localized: "in \(days) days")
    }
  }
}
