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
  let subcat: String?
  let hebrew: String
  var link: String?
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    date = try container.decode(String.self, forKey: .date)
    category = try container.decode(String.self, forKey: .category)
    subcat = try container.decodeIfPresent(String.self, forKey: .subcat)
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
  
  // MARK: - Helper Methods
  
  var isFast: Bool {
    return subcat == "fast"
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
  
  // MARK: - Holidays to exclude from displaying
  // These holidays are considered too minor or specific to show as main holidays
  private let excludedHolidayTitles: Set<String> = [
    "Shabbat Nachamu",
    "שבת נחמו" // Hebrew for Shabbat Nachamu
  ]
  
  @MainActor
  func fetchShabbatTimes(for city: City, candleLightingMinutes: Int = 20, forDate: Date? = nil) async {
    isLoading = true
    
    defer {
      isLoading = false
    }
    
    let beforeSunset = candleLightingMinutes
    let latitude = city.coordinate.latitude
    let longitude = city.coordinate.longitude
    
    var urlString = "https://www.hebcal.com/shabbat?cfg=json&geo=pos&latitude=\(latitude)&longitude=\(longitude)&M=on&b=\(beforeSunset)"
    
    if let date = forDate {
      let calendar = Calendar.current
      let year = calendar.component(.year, from: date)
      let month = calendar.component(.month, from: date)
      let day = calendar.component(.day, from: date)
      urlString += "&gy=\(year)&gm=\(month)&gd=\(day)"
    }
    
    guard let url = URL(string: urlString) else {
      error = NSError(domain: "Invalid URL", code: -1)
      return
    }
    
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      let response = try JSONDecoder().decode(ShabbatResponse.self, from: data)

      // Set timezone immediately so all date math uses the correct zone
      timeZone = response.location.tzid

      // Build ordered pairs of (candle lighting, havdalah)
      let tzForParsing = timeZone
      let candleEvents: [(item: ShabbatItem, date: Date)] = response.items
        .filter { $0.category == "candles" }
        .compactMap { item in
          guard let d = item.formattedDate(timeZone: tzForParsing) else { return nil }
          return (item, d)
        }
        .sorted { $0.date < $1.date }

      let havdalahEvents: [(item: ShabbatItem, date: Date)] = response.items
        .filter { $0.category == "havdalah" }
        .compactMap { item in
          guard let d = item.formattedDate(timeZone: tzForParsing) else { return nil }
          return (item, d)
        }
        .sorted { $0.date < $1.date }

      var pairs: [(c: (item: ShabbatItem, date: Date), h: (item: ShabbatItem, date: Date))] = []
      var hIndex = 0
      for c in candleEvents {
        while hIndex < havdalahEvents.count && havdalahEvents[hIndex].date <= c.date {
          hIndex += 1
        }
        if hIndex < havdalahEvents.count {
          pairs.append((c: c, h: havdalahEvents[hIndex]))
        }
      }

      // Choose the current pair (if now is between c..h),
      // otherwise the next upcoming pair, otherwise fallback to the latest known pair
      var cal = Calendar.current
      if let tzid = timeZone, let tz = TimeZone(identifier: tzid) { cal.timeZone = tz }
      let now = Date()

      let currentPair = pairs.first(where: { now >= $0.c.date && now <= $0.h.date })
        ?? pairs.first(where: { now < $0.c.date })
        ?? pairs.last

      candleLighting = currentPair?.c.item ?? candleEvents.first?.item
      havdalah = currentPair?.h.item ?? havdalahEvents.first?.item

      // Parasha (take the first available within the dataset)
      parasah = response.items.first { $0.category == "parashat" }

      // Find the current or next holiday based on date
      // Exclude modern and minor holidays, as well as specific holidays by title
      let allHolidays = response.items.filter { item in
        item.category == "holiday" &&
        item.subcat != "modern" &&
        item.subcat != "minor" &&
        !excludedHolidayTitles.contains(item.title)
      }

      holiday = findCurrentOrNextHoliday(from: allHolidays)

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
