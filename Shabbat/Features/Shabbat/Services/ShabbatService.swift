import Foundation
import SwiftUI

struct ShabbatResponse: Codable {
  let items: [ShabbatItem]
  let location: Location
}

struct Location: Codable {
  let title: String
  let city: String
  let tzid: String
  let latitude: Double
  let longitude: Double
}

struct ShabbatItem: Codable, Identifiable {
  let title: String
  let date: String
  let category: String
  let hebrew: String
  var link: String?
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    date = try container.decode(String.self, forKey: .date)
    category = try container.decode(String.self, forKey: .category)
    hebrew = try container.decode(String.self, forKey: .hebrew)
    link = try container.decodeIfPresent(String.self, forKey: .link)
    
    // Set the title property based on app language
    let appLanguage = Locale.current.language.languageCode?.identifier ?? "en"
    let decodedTitle = try container.decode(String.self, forKey: .title)
    title = appLanguage == "he" ? hebrew : decodedTitle
  }
  
  var id: String {
    "\(category)-\(date)"
  }
  
  func formattedDate(timeZone: String?) -> Date? {
    // First try to parse as full ISO8601 datetime (for candles/havdalah)
    let iso8601Formatter = ISO8601DateFormatter()
    iso8601Formatter.formatOptions = [.withInternetDateTime]
    if let date = iso8601Formatter.date(from: date) {
      return date
    }
    
    // If that fails, try to parse as date-only (API format holidays is yyyy-MM-dd)
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    if let timeZoneId = timeZone {
      dateFormatter.timeZone = TimeZone(identifier: timeZoneId)
    }
    return dateFormatter.date(from: date)
  }
}

@Observable
class ShabbatService {
  @MainActor private(set) var isLoading = false
  private(set) var timeZone: String?
  var candleLighting: ShabbatItem?
  var havdalah: ShabbatItem?
  var parasah: ShabbatItem?
  var holiday: ShabbatItem?
  var error: Error?
  
  @MainActor
  func fetchShabbatTimes(for city: City, candleLightingMinutes: Int = 20) async {
    isLoading = true
    
    defer {
      isLoading = false
    }
    
    let beforeSunset = candleLightingMinutes
    let latitude = city.coordinate.latitude
    let longitude = city.coordinate.longitude
    
    let urlString = "https://www.hebcal.com/shabbat?cfg=json&geo=pos&latitude=\(latitude)&longitude=\(longitude)&M=on&b=\(beforeSunset)"
    
    guard let url = URL(string: urlString) else {
      error = NSError(domain: "Invalid URL", code: -1)
      return
    }
    
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      let response = try JSONDecoder().decode(ShabbatResponse.self, from: data)
      
      candleLighting = response.items.first { $0.category == "candles" }
      havdalah = response.items.first { $0.category == "havdalah" }
      parasah = response.items.first { $0.category == "parashat" }
      
      // Find the current or next holiday based on date
      let allHolidays = response.items.filter { $0.category == "holiday" }
      holiday = findCurrentOrNextHoliday(from: allHolidays)
      
      timeZone = response.location.tzid
      
      error = nil
    } catch {
      self.error = error
      print(error)
    }
  }
  
  private func findCurrentOrNextHoliday(from holidays: [ShabbatItem]) -> ShabbatItem? {
    guard !holidays.isEmpty else { return nil }
    
    let now = Date()
    var calendar = Calendar.current
    
    // Use the API's timezone
    if let timeZoneId = timeZone {
      calendar.timeZone = TimeZone(identifier: timeZoneId) ?? TimeZone.current
    }
    
    let today = calendar.startOfDay(for: now)
    
    // Find the closest holiday that's today or in the future
    return holidays
      .compactMap { holiday -> (ShabbatItem, Date)? in
        guard let holidayDate = holiday.formattedDate(timeZone: timeZone) else { return nil }
        let holidayDay = calendar.startOfDay(for: holidayDate)
        return holidayDay >= today ? (holiday, holidayDay) : nil
      }
      .min(by: { $0.1 < $1.1 })?
      .0
  }
}
