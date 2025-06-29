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
    shabbatService.parasah?.title ?? shabbatService.holiday?.title ?? "Error"
  }
  
  var shouldShowHolidayTitle: Bool {
    holiday != nil
  }
  
  var holidayTitle: String? {
    holiday?.title
  }
  
  var shouldShowParashaButton: Bool {
    // Only show parasha button if there's no holiday
    return holiday == nil
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
  
  func hebrewCalendarDay(from number: Int) -> String {
    if number <= 0 || number > 31 { return "" }
    if number == 15 { return "ט״ו" }
    if number == 16 { return "ט״ז" }

    let letters: [(Int, String)] = [
        (30, "ל"), (20, "כ"), (10, "י"), (9, "ט"), (8, "ח"),
        (7, "ז"), (6, "ו"), (5, "ה"), (4, "ד"), (3, "ג"),
        (2, "ב"), (1, "א")
    ]

    var num = number
    var components = [String]()

    for (value, letter) in letters where num >= value {
        let count = num / value
        components.append(String(repeating: letter, count: count))
        num %= value
        if num == 0 { break }
    }

    let joined = components.joined()
    return joined.count > 1
        ? joined.dropLast() + "״" + joined.suffix(1)
        : joined + "׳"
  }

  func hebrewDateString(from date: Date, timeZone: TimeZone) -> (hebrewDay: String, month: String) {
    var calendar = Calendar(identifier: .hebrew)
    calendar.timeZone = timeZone

    let components = calendar.dateComponents([.day], from: date)
    let day = components.day ?? 1

    // Decide how to format the day
    let useHebrewLetters = Locale.current.identifier.hasPrefix("he")
    let formattedDay = useHebrewLetters
        ? hebrewCalendarDay(from: day)
        : String(day)

    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = timeZone
    formatter.dateFormat = "MMMM"
    let month = formatter.string(from: date)

    return (formattedDay, month)
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
    
    let gregorianRange: String
    if startMonth == endMonth {
      gregorianRange = "\(startDay) - \(endDay) \(startMonth)"
    } else {
      gregorianRange = "\(startDay) \(startMonth) - \(endDay) \(endMonth)"
    }

    let start = hebrewDateString(from: startDate, timeZone: timeZone)
    let end = hebrewDateString(from: endDate, timeZone: timeZone)

    let hebrewRange: String
    if start.month == end.month {
        hebrewRange = "\(start.hebrewDay) - \(end.hebrewDay) \(start.month)"
    } else {
        hebrewRange = "\(start.hebrewDay) \(start.month) - \(end.hebrewDay) \(end.month)"
    }

    return "\(gregorianRange)\n\(hebrewRange)"
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
