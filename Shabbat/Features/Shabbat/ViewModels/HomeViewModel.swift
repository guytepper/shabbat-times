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
    shabbatService.parasah?.title ?? "Error"
  }
  
  var shouldShowHolidayTitle: Bool {
    holiday != nil
  }
  
  var holidayTitle: String? {
    holiday?.title
  }
  
  var isFastDay: Bool {
    holiday?.isFast ?? false
  }
  
  var shouldShowParashaButton: Bool {
    // Show parasha button if there's a parasha, unless it's a major holiday that replaces Torah reading
    // Special Shabbat names (subcat: "shabbat") should still show the parasha
    if let holiday = holiday {
      return holiday.subcat == "shabbat" && shabbatService.parasah != nil
    }
    return shabbatService.parasah != nil
  }
  
  private var holiday: ShabbatItem? {
    shabbatService.holiday
  }
  
  var isShabbat: Bool {
    guard let candleLighting = candleLighting,
          let havdalah = havdalah else {
      return false
    }
    
    let now = Date()
    var calendar = Calendar.current
    calendar.timeZone = timeZone 
    
    let nowDate = calendar.startOfDay(for: now)
    let candleLightingDate = calendar.startOfDay(for: candleLighting)
    let havdalahDate = calendar.startOfDay(for: havdalah)
    
    return nowDate == candleLightingDate || nowDate == havdalahDate
  }
  
  func loadShabbatTimes() async {
    if let city = cityManager?.getCurrentCity() {
      let settingsManager = SettingsManager(modelContext: modelContext)
      var candleLightingMinutes = settingsManager.settings.candleLightingMinutesBeforeSunset
      
      // If user hasn't customized their setting and the city is Jerusalem, set default to 40 minutes
      if !settingsManager.settings.hasCustomizedCandleLightingMinutes && (city.name == "Jerusalem" || city.name == "ירושלים") {
        candleLightingMinutes = 40
        settingsManager.updateSettings { settings in
          settings.candleLightingMinutesBeforeSunset = 40
        }
      }
      
      await shabbatService.fetchShabbatTimes(for: city, candleLightingMinutes: candleLightingMinutes)
    }
  }
  
  func loadParasha() async throws {
    try await parashaService.fetchCurrentParasha()
  }
  
  func saveNewCity(city: City) {
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
    
    var calendar = Calendar.current
    calendar.timeZone = timeZone
    let now = Date()
    
    let startOfToday = calendar.startOfDay(for: now)
    let startOfShabbat = calendar.startOfDay(for: candleLighting)
    let days = calendar.dateComponents([.day], from: startOfToday, to: startOfShabbat).day ?? 0
    
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
